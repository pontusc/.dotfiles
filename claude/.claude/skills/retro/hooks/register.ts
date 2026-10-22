import type { EngineInterface, Register, SessionMessage } from 'claude-code'

const TMUX_SESSION = 'retros'
const DOTFILES = 'dotfiles'
const RETROS_DIR = 'retros'
const FALLBACK_MODEL = 'sonnet'
const FALLBACK_MESSAGES = 80
const REVIEW_MODEL = 'opus'
const REVIEW_INSTRUCTIONS = '~/.claude/skills/retro/instructions/retro-agent.md'

type Facts = {
  slug: string
  task: string
  happened: string
  correction: string
}

type Handoff = Facts & {
  incident: string
  date: string
  cwd: string
  logPath: string
}

const FACTS_SHAPE = `Answer with one JSON object and nothing else, keys:
"slug": 2 to 4 lowercase hyphen-joined words naming the failure, not the task
"task": what the user originally asked for, quoted from their message
"happened": the approach the assistant took around the incident, with file:line refs where edits were made
"correction": the user's correction messages quoted verbatim, and how the corrected version differed`

function factsPrompt(incident: string): string {
  const framing = incident === ''
    ? 'Identify where in this session the user materially corrected the assistant.'
    : `The user names the incident as: ${incident}`
  return `${framing}\nFacts only, no root cause.\n${FACTS_SHAPE}`
}

function transcriptText(messages: readonly SessionMessage[]): string {
  return messages
    .slice(-FALLBACK_MESSAGES)
    .map(message => `${message.role}: ${message.text}`)
    .join('\n\n')
}

type Extracted = Facts | { failure: string }

function parseFacts(reply: string): Extracted {
  const start = reply.indexOf('{')
  const end = reply.lastIndexOf('}')
  if (start === -1 || end <= start) return { failure: 'reply holds no JSON object' }
  let parsed: unknown
  try {
    parsed = JSON.parse(reply.slice(start, end + 1))
  } catch {
    return { failure: 'reply is not valid JSON' }
  }
  if (typeof parsed !== 'object' || parsed === null) return { failure: 'reply is not a JSON object' }
  const { slug, task, happened, correction } = parsed as Record<string, unknown>
  if (typeof slug !== 'string' || typeof task !== 'string' || typeof happened !== 'string' || typeof correction !== 'string') {
    return { failure: 'reply misses one of slug, task, happened, correction' }
  }
  const safeSlug = slug.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
  return safeSlug === '' ? { failure: 'reply has an empty slug' } : { slug: safeSlug, task, happened, correction }
}

async function extractFacts($: EngineInterface, incident: string): Promise<Extracted> {
  const prompt = factsPrompt(incident)
  const forked = await $.model.fork({ prompt })
  if (forked.isAnswered) return parseFacts(forked.text)
  if (forked.reason !== 'nothing-to-fork') return { failure: `fork ${forked.reason}` }

  const completed = await $.model.complete({
    model: FALLBACK_MODEL,
    system: prompt,
    prompt: transcriptText(await $.session.messages()),
  })
  return completed.isAnswered ? parseFacts(completed.text) : { failure: `completion ${completed.reason}` }
}

async function sessionLogPath($: EngineInterface, home: string, cwd: string, sessionId: string): Promise<string> {
  const projectDir = `${home}/.claude/projects/${cwd.replace(/[^a-zA-Z0-9]/g, '-')}`
  const ownLog = `${projectDir}/${sessionId}.jsonl`
  if (await $.fs.exists(ownLog)) return ownLog
  const newest = (await $.fs.list(projectDir).catch(() => []))
    .filter(entry => entry.kind === 'file' && entry.name.endsWith('.jsonl'))
    .sort((a, b) => b.mtimeMs - a.mtimeMs)[0]
  return newest === undefined ? `unverified, ${ownLog} is missing` : `${projectDir}/${newest.name} (newest, own log missing)`
}

function localDate(epochMs: number): string {
  const date = new Date(epochMs)
  const pad = (part: number): string => String(part).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

function handoffDoc(handoff: Handoff): string {
  return `# Retro: ${handoff.slug}

${handoff.date} · ${handoff.cwd} · session log: ${handoff.logPath}

## Incident (user)

${handoff.incident === '' ? 'not stated, see Correction' : handoff.incident}

## Task

${handoff.task}

## What happened

${handoff.happened}

## Correction

${handoff.correction}
`
}

async function openReview($: EngineInterface, dotfilesDir: string, docPath: string, slug: string): Promise<string> {
  const command = `claude --model ${REVIEW_MODEL} 'Follow ${REVIEW_INSTRUCTIONS} for ${docPath}'`
  const windowArgs = ['-n', slug, '-c', dotfilesDir, command]
  try {
    const existing = await $.process.run(['tmux', 'has-session', '-t', `=${TMUX_SESSION}`])
    const opened = existing.exitCode === 0
      ? await $.process.run(['tmux', 'new-window', '-t', `=${TMUX_SESSION}`, ...windowArgs])
      : await $.process.run(['tmux', 'new-session', '-d', '-s', TMUX_SESSION, ...windowArgs])
    return opened.exitCode === 0 ? `session at ${TMUX_SESSION}:${slug}` : `tmux failed: ${opened.stderr.trim()}`
  } catch (error) {
    return `tmux not started: ${error instanceof Error ? error.message : String(error)}`
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'retro',
      description: 'Write a retro handoff doc from this session and open the review in tmux',
      argumentHint: '[one line naming the failure]',
    })
    return next(e)
  })

  on('command.run', { command: 'retro' }, async ($, e) => {
    const incident = e.args.trim()
    const facts = await extractFacts($, incident)
    if ('failure' in facts) return { text: `retro: ${facts.failure}, nothing written` }

    const home = await $.env.get('HOME')
    if (home === undefined) return { text: 'retro: HOME is unset, nothing written' }
    const dotfilesDir = `${home}/${DOTFILES}`
    const date = localDate(await $.clock.now())
    const docPath = `${RETROS_DIR}/${date}-${facts.slug}.md`
    const cwd = await $.session.cwd()
    await $.fs.write(`${dotfilesDir}/${docPath}`, handoffDoc({
      ...facts,
      incident,
      date,
      cwd,
      logPath: await sessionLogPath($, home, cwd, await $.session.id()),
    }))

    const review = await openReview($, dotfilesDir, docPath, facts.slug)
    return { text: `Retro doc: ${docPath}, ${review}` }
  }).catch(() => ({ text: 'retro: failed, see the debug log' }))
}
