import type { ModelUsage, On } from 'claude-code'
import type { Engine } from 'claude-code/testing'
import { describe, expect, mock, test } from 'claude-code/testing'

const USAGE: ModelUsage = { input_tokens: 1, output_tokens: 1, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 }
const FACTS = JSON.stringify({ slug: 'Prose Slack Message', task: 'send it', happened: 'sent prose', correction: 'no, a spec' })
const DOC = '/home/me/dotfiles/retros/2026-10-22-prose-slack-message.md'
const OWN_LOG = '/home/me/.claude/projects/-home-me-repo/sess-1.jsonl'

type Recorded = {
  writes: { path: string; text: string }[]
  runs: string[][]
  forkPrompts: string[]
  completePrompts: string[]
}

type HostOptions = {
  fork?: 'answers' | 'nothing'
  forkText?: string
  tmuxHasSession?: boolean
  tmuxStderr?: string
  ownLogExists?: boolean
}

function fakeHost(on: On, options: HostOptions = {}): Recorded {
  const recorded: Recorded = { writes: [], runs: [], forkPrompts: [], completePrompts: [] }
  const forkText = options.forkText ?? `\`\`\`json\n${FACTS}\n\`\`\``
  mock.env(on, { HOME: '/home/me' })
  mock.clock(on, { now: Date.UTC(2026, 9, 22, 12) })
  on('session.cwd', () => ({ value: '/home/me/repo' }))
  on('session.id', () => ({ value: 'sess-1' }))
  on('session.messages', () => ({ value: [{ role: 'user', text: 'send it', toolUses: [] }] }))
  on('model.fork', ($, e) => {
    recorded.forkPrompts.push(e.prompt)
    return options.fork === 'nothing'
      ? { value: { isAnswered: false, reason: 'nothing-to-fork' } }
      : { value: { isAnswered: true, text: forkText, usage: USAGE } }
  })
  on('model.complete', ($, e) => {
    recorded.completePrompts.push(e.prompt)
    return { value: { isAnswered: true, text: FACTS, usage: USAGE } }
  })
  on('fs.exists', ($, e) => ({ value: e.path === OWN_LOG && (options.ownLogExists ?? true) }))
  on('fs.list', () => ({
    value: [
      { name: 'old.jsonl', kind: 'file', size: 1, mtimeMs: 1, isLink: false },
      { name: 'newer.jsonl', kind: 'file', size: 1, mtimeMs: 2, isLink: false },
      { name: 'notes.txt', kind: 'file', size: 1, mtimeMs: 3, isLink: false },
    ],
  }))
  on('fs.write', ($, e) => {
    recorded.writes.push({ path: e.path, text: e.text })
    return { value: undefined }
  })
  on('process.run', ($, e) => {
    recorded.runs.push([...e.argv])
    const isHasSession = e.argv[1] === 'has-session'
    const exitCode = (isHasSession && !(options.tmuxHasSession ?? true)) || options.tmuxStderr !== undefined ? 1 : 0
    return { value: { exitCode, stdout: '', stderr: options.tmuxStderr ?? '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  return recorded
}

async function retro($: Engine, args = ''): Promise<string | undefined> {
  const { text } = await $.command.run({
    command: 'retro',
    args,
    origin: { kind: 'composer' },
    presentation: { isFullscreen: false, columns: 80 },
  })
  return text
}

describe('retro', () => {
  test('writes the doc from the fork and opens a window in the existing retros session', async ($, on) => {
    const host = fakeHost(on)
    const text = await retro($, 'sent prose instead of a spec')
    expect(host.forkPrompts[0]).toContain('sent prose instead of a spec')
    expect(host.completePrompts).toEqual([])
    expect(host.writes.map(write => write.path)).toEqual([DOC])
    expect(host.writes[0]?.text).toContain('# Retro: prose-slack-message')
    expect(host.writes[0]?.text).toContain(`session log: ${OWN_LOG}`)
    expect(host.writes[0]?.text).toContain('sent prose instead of a spec')
    expect(host.writes[0]?.text).toContain('no, a spec')
    expect(host.runs.map(argv => argv.slice(1, 4))).toEqual([
      ['has-session', '-t', '=retros'],
      ['new-window', '-t', '=retros'],
    ])
    expect(host.runs[1]?.at(-1)).toContain('retro-agent.md for retros/2026-10-22-prose-slack-message.md')
    expect(text).toBe('Retro doc: retros/2026-10-22-prose-slack-message.md, session at retros:prose-slack-message')
  })

  test('an empty incident line leaves a placeholder in the doc', async ($, on) => {
    const host = fakeHost(on)
    await retro($)
    expect(host.writes[0]?.text).toContain('## Incident (user)\n\nnot stated, see Correction')
  })

  test('starts the retros session when none exists', async ($, on) => {
    const host = fakeHost(on, { tmuxHasSession: false })
    await retro($)
    expect(host.runs.map(argv => argv[1])).toEqual(['has-session', 'new-session'])
  })

  test('reports tmux stderr when the window cannot be opened', async ($, on) => {
    fakeHost(on, { tmuxStderr: 'no server running\n' })
    const text = await retro($)
    expect(text).toBe('Retro doc: retros/2026-10-22-prose-slack-message.md, tmux failed: no server running')
  })

  test('falls back to a completion over the messages when there is nothing to fork', async ($, on) => {
    const host = fakeHost(on, { fork: 'nothing' })
    await retro($)
    expect(host.completePrompts).toEqual(['user: send it'])
    expect(host.writes).toHaveLength(1)
  })

  test('points at the newest log in the project dir when the own log is missing', async ($, on) => {
    const host = fakeHost(on, { ownLogExists: false })
    await retro($)
    expect(host.writes[0]?.text).toContain('session log: /home/me/.claude/projects/-home-me-repo/newer.jsonl (newest, own log missing)')
  })

  test('writes nothing and names the cause when the reply is not the facts shape', async ($, on) => {
    const host = fakeHost(on, { forkText: 'I cannot tell' })
    const text = await retro($)
    expect(host.writes).toEqual([])
    expect(host.runs).toEqual([])
    expect(text).toBe('retro: reply holds no JSON object, nothing written')
  })
})
