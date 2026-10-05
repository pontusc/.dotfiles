import type { Register } from 'claude-code'

const COMMAND_START = String.raw`(?:^|[;&|(]|\b(?:do|then|else|sudo|xargs))\s*`
const VARIABLE_PATH = String.raw`([^\s;&|<>]*\$\{?[A-Za-z_][^\s;&|<>]*)`
const RECURSIVE_FLAG = String.raw`\s(?:-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)\b`

const REDIRECT_TARGET = new RegExp(String.raw`(?:^|[^<>&\d=-])[\d&]?>(?!>)\|?\s*${VARIABLE_PATH}`, 'gm')
const RECURSIVE_REMOVE_TARGET = new RegExp(String.raw`${COMMAND_START}rm\b(?=[^;&|\n]*${RECURSIVE_FLAG})[^;&|\n]*\s${VARIABLE_PATH}`, 'gm')
const VARIABLE_NAME = /\$\{?([A-Za-z_]\w*)/g
const ASSIGNMENT = /(?:^|[;&|(\s])(?:(?:export|local|readonly)\s+)?([A-Za-z_]\w*)=/gm
const LOOP = /\bfor\s+([A-Za-z_]\w*)\s+in\s+([^;\n]*)/g
const TEST_EXPRESSION = /\[\[[^\]\n]*\]\]/g

const HEREDOC_OPENER = /<<(-?)\s*(?:'([^'\n]+)'|"([^"\n]+)"|\\?([^\s;&|<>()'"]+))/y
const QUOTED_SPECIAL = { "'": /[\s<>;&|$]/g, '"': /[\s<>;&|]/g } as const
const FILE_REDIRECT_TARGET = /(?<![<>\d&])[1&]?>>?\|?\s*([^\s;&|<>(][^\s;&|<>]*)/g
const TEE_TARGET = /\btee\s+(?:-\S+\s+)*([^\s;&|<>]+)/g
const REMOTE_OR_PRIVILEGED = /\b(?:sudo|ssh|kubectl|docker|podman)\b/
const PYTHON_INTERPRETER = /(?:^|[\s(])python3?\s/
const PYTHON_WRITE = /\bopen\((?:[^()]|\([^()]*\))*?,\s*(?:mode\s*=\s*)?['"][rwaxbt+]*[wax+][rwaxbt+]*['"]\s*[,)]|\.write_(?:text|bytes)\(/
const PYTHON_LITERAL_READ = /\bopen\(\s*(['"])[^'"\n]*\1\s*(?:,\s*(?:mode\s*=\s*)?['"][rbt]*['"]\s*)?\)|\bPath\(\s*(['"])[^'"\n]*\2\s*\)\.read_(?:text|bytes)\(/g
const SCOPE_CHANGE = /(?:^|[;&|(\s])(?:export\s+)?([A-Za-z_]\w*)=([^\s;&|)]*)|\b(cd|pushd)\s+(?:-\S*\s+)*([^\s;&|)]+)|\b(popd)\b/gm
const INNERMOST_GROUP = /\$?\([^()]*\)/g
const VARIABLE_REFERENCE = /\$\{?([A-Za-z_]\w*)\}?/g

type Quote = keyof typeof QUOTED_SPECIAL

type Heredoc = {
  opener: string
  line: string
  before: string
  body: string
}

type PendingHeredoc = {
  opener: string
  delimiter: string
  stripTabs: boolean
}

type Script = {
  shell: string
  heredocs: readonly Heredoc[]
}

type Scope = {
  values: ReadonlyMap<string, string>
  cwd: string | null
}

function isScratch(path: string): boolean {
  return path.startsWith('/tmp/') || path.startsWith('/dev/')
}

function sanitize(text: string, quote: Quote): string {
  return text.replace(QUOTED_SPECIAL[quote], '_')
}

function isWordStart(command: string, index: number): boolean {
  return index === 0 || /[\s;&|()]/.test(command[index - 1] ?? '')
}

function readBody(command: string, start: number, heredoc: PendingHeredoc): { body: string; next: number } {
  let lineStart = start
  while (lineStart < command.length) {
    const newline = command.indexOf('\n', lineStart)
    const lineEnd = newline === -1 ? command.length : newline
    const text = command.slice(lineStart, lineEnd)
    if ((heredoc.stripTabs ? text.replace(/^\t+/, '') : text) === heredoc.delimiter) {
      return { body: command.slice(start, lineStart), next: lineEnd + 1 }
    }
    lineStart = lineEnd + 1
  }
  return { body: command.slice(start), next: command.length }
}

function arithmeticEnd(command: string, start: number): number | null {
  let depth = 0
  for (let index = start; index < command.length; index += 1) {
    if (command[index] === '(') depth += 1
    else if (command[index] === ')') {
      if (depth > 0) depth -= 1
      else return command[index + 1] === ')' ? index + 2 : null
    }
  }
  return null
}

function parseScript(command: string): Script {
  const heredocs: Heredoc[] = []
  const pending: PendingHeredoc[] = []
  const frames: ('double' | number)[] = []
  let quoted = ''
  let shell = ''
  let lineStart = 0
  let index = 0

  while (index < command.length) {
    const char = command[index] ?? ''
    const frame = frames.at(-1)

    if (frame === 'double') {
      if (char === '\\') {
        quoted += command.slice(index, index + 2)
        index += 2
      } else if (char === '"') {
        shell += sanitize(quoted, '"')
        quoted = ''
        frames.pop()
        index += 1
      } else if (command.startsWith('$((', index) && arithmeticEnd(command, index + 3) !== null) {
        const end = arithmeticEnd(command, index + 3) ?? command.length
        quoted += command.slice(index, end)
        index = end
      } else if (command.startsWith('$(', index)) {
        shell += `${sanitize(quoted, '"')}$(`
        quoted = ''
        frames.push(1)
        index += 2
      } else {
        quoted += char
        index += 1
      }
      continue
    }

    if (char === '\\') {
      shell += command[index + 1] === '\n' ? ' ' : command.slice(index, index + 2)
      index += 2
      continue
    }
    if (char === "'") {
      const close = command.indexOf("'", index + 1)
      const end = close === -1 ? command.length : close
      shell += sanitize(command.slice(index + 1, end), "'")
      index = end + 1
      continue
    }
    if (char === '"') {
      frames.push('double')
      index += 1
      continue
    }
    const arithmetic = command.startsWith('((', index) ? arithmeticEnd(command, index + 2) : null
    if (arithmetic !== null) {
      shell += sanitize(command.slice(index, arithmetic), '"')
      index = arithmetic
      continue
    }
    if (char === '#' && isWordStart(command, index)) {
      const newline = command.indexOf('\n', index)
      index = newline === -1 ? command.length : newline
      continue
    }
    if (command.startsWith('<<', index) && command[index + 2] !== '<' && command[index - 1] !== '<') {
      HEREDOC_OPENER.lastIndex = index
      const match = HEREDOC_OPENER.exec(command)
      if (match !== null) {
        pending.push({ opener: match[0], delimiter: match[2] ?? match[3] ?? match[4] ?? '', stripTabs: match[1] === '-' })
        shell += match[0]
        index += match[0].length
        continue
      }
    }
    if (typeof frame === 'number' && char === '(') frames[frames.length - 1] = frame + 1
    if (typeof frame === 'number' && char === ')') {
      if (frame === 1) frames.pop()
      else frames[frames.length - 1] = frame - 1
    }
    if (char === '\n' && pending.length > 0) {
      const line = shell.slice(lineStart)
      const before = shell.slice(0, lineStart)
      let bodyStart = index + 1
      for (const heredoc of pending) {
        const { body, next } = readBody(command, bodyStart, heredoc)
        heredocs.push({ opener: heredoc.opener, line, before, body })
        bodyStart = next
      }
      pending.length = 0
      shell += '\n'
      lineStart = shell.length
      index = bodyStart
      continue
    }
    shell += char
    if (char === '\n') lineStart = shell.length
    index += 1
  }

  shell += sanitize(quoted, '"')
  for (const heredoc of pending) {
    heredocs.push({ opener: heredoc.opener, line: shell.slice(lineStart), before: shell.slice(0, lineStart), body: '' })
  }
  return { shell, heredocs }
}

function hasUnresolvedTarget(shell: string): boolean {
  const statements = shell.replace(TEST_EXPRESSION, '_')
  const assigned = new Set([...statements.matchAll(ASSIGNMENT)].map(match => match[1] ?? ''))
  const literalLoopNames = new Set(
    [...statements.matchAll(LOOP)].filter(match => !/[*?$`(\[]/.test(match[2] ?? '')).map(match => match[1] ?? ''),
  )
  const isRelative = (target: string): boolean => {
    const leading = /^\$\{?([A-Za-z_]\w*)/.exec(target)?.[1]
    return !target.startsWith('/') && (leading === undefined || !assigned.has(leading))
  }
  const unresolved = (target: string, loopResolves: boolean): boolean =>
    [...target.matchAll(VARIABLE_NAME)].some(([, name = '']) =>
      !assigned.has(name) && !(loopResolves && literalLoopNames.has(name) && isRelative(target)),
    )
  return (
    [...statements.matchAll(REDIRECT_TARGET)].some(([, target = '']) => unresolved(target, true)) ||
    [...statements.matchAll(RECURSIVE_REMOVE_TARGET)].some(([, target = '']) => unresolved(target, false))
  )
}

function expand(word: string, values: ReadonlyMap<string, string>): string {
  return word.replace(VARIABLE_REFERENCE, (reference, name: string) => values.get(name) ?? reference)
}

function withoutGroups(text: string): string {
  const collapsed = text.replace(INNERMOST_GROUP, group => (group.startsWith('$') ? '$_' : '_'))
  return collapsed === text ? text : withoutGroups(collapsed)
}

function scopeOf(text: string): Scope {
  const values = new Map<string, string>()
  const pushed: (string | null)[] = []
  let cwd: string | null = '.'
  for (const [, name, value, verb, directory, popd] of withoutGroups(text).matchAll(SCOPE_CHANGE)) {
    if (popd !== undefined) {
      cwd = pushed.length > 0 ? (pushed.pop() ?? null) : null
      continue
    }
    if (verb === 'pushd') pushed.push(cwd)
    if (name !== undefined) {
      const resolved = expand(value ?? '', values)
      if (/[$`]/.test(resolved)) values.delete(name)
      else values.set(name, resolved)
      continue
    }
    const resolved = expand(directory ?? '', values)
    if (resolved.includes('$') || resolved === '-') cwd = null
    else if (/^[/~]/.test(resolved)) cwd = resolved
    else if (cwd !== null) cwd = `${cwd}/${resolved}`
  }
  return { values, cwd }
}

function writesOutsideScratch(heredoc: Heredoc): boolean {
  const segment = heredoc.line.split(/&&|\|\||;/).find(part => part.includes(heredoc.opener)) ?? ''
  const pipeline = segment.split(/(?<!>)\|/)
  const producerIndex = pipeline.findIndex(part => part.includes(heredoc.opener))
  const producer = pipeline[producerIndex] ?? ''
  const { values, cwd } = scopeOf(heredoc.before + heredoc.line.slice(0, heredoc.line.indexOf(heredoc.opener)))
  if (PYTHON_INTERPRETER.test(producer)) {
    const touchesScratch = /\/(?:tmp|dev)\//.test(heredoc.body) || expand(producer, values).includes('/tmp/')
    const namesOutsidePath = /['"](?:\/(?!tmp\/|dev\/)|~\/)/.test(heredoc.body.replace(PYTHON_LITERAL_READ, '_'))
    const writesRelativeOutside = cwd !== null && !isScratch(`${cwd}/`)
    return PYTHON_WRITE.test(heredoc.body) && !touchesScratch && (namesOutsidePath || writesRelativeOutside)
  }
  if (!/\b(?:cat|tee)\b/.test(producer)) return false

  const teeTargets = (part: string): RegExpMatchArray[] => REMOTE_OR_PRIVILEGED.test(part) ? [] : [...part.matchAll(TEE_TARGET)]
  const targets = [
    ...producer.matchAll(FILE_REDIRECT_TARGET),
    ...teeTargets(producer),
    ...pipeline.slice(producerIndex + 1).flatMap(teeTargets),
  ].map(match => expand(match[1] ?? '', values))
  return targets.some(target => {
    if (target.includes('$')) return false
    if (/^[/~]/.test(target)) return !isScratch(target)
    return cwd !== null && !isScratch(`${cwd}/${target}`)
  })
}

export const register: Register = on => {
  on('tool.call', { tool: 'Bash' }, ($, e, next) => {
    const script = parseScript(e.command)
    if (hasUnresolvedTarget(script.shell)) {
      return { deny: `${$.plugin.name}: a truncating redirect or recursive rm target holds a shell variable this command never assigns, which dcg cannot resolve and blocks. Spell out the literal absolute path.` }
    }
    if (script.heredocs.some(writesOutsideScratch)) {
      return { deny: `${$.plugin.name}: a heredoc writes a file outside /tmp. Use Edit or Write, they read before writing and run the PostToolUse checks.` }
    }
    return next(e)
  })
}
