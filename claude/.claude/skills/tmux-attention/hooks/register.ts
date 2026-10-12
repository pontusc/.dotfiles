import type { AgentStatus, EngineInterface, ProcessRunResult, Register } from 'claude-code'

const DONE_AFTER_MS = 20_000
const BUSY_AGENT_STATUSES: ReadonlySet<AgentStatus> = new Set(['pending', 'running', 'waiting'])

let isFlagRaised = false
let promptedAt: number | undefined
let isWakeUp = false
const askingToolUseIds = new Set<string>()

function tmux($: EngineInterface, args: readonly string[]): Promise<ProcessRunResult> {
  return $.process.run(['tmux', ...args])
}

async function clearFlag($: EngineInterface): Promise<void> {
  const pane = await $.env.get('TMUX_PANE')
  if (pane === undefined || !isFlagRaised) return
  isFlagRaised = false
  await tmux($, ['set-option', '-w', '-t', pane, '-u', '@claude'])
}

async function raiseFlag($: EngineInterface, flag: 'ask' | 'done'): Promise<void> {
  const pane = await $.env.get('TMUX_PANE')
  if (pane === undefined) return

  const shown = await tmux($, [
    'display', '-p', '-t', pane, '-F',
    '#{pane_active}\t#{window_active}\t#{session_attached}\t#{session_name}',
  ])
  if (shown.exitCode !== 0) return
  const [paneActive, windowActive, sessionAttached, sessionName = ''] = shown.stdout.trim().split('\t')

  const clients = await tmux($, ['list-clients', '-t', sessionName, '-F', '#{client_flags}'])
  const isFocused = clients.stdout.split('\n').some(flags => flags.includes('focused'))
  const isWatched = paneActive === '1' && windowActive === '1' && sessionAttached !== '0' && isFocused
  if (isWatched) return

  isFlagRaised = true
  await tmux($, ['set-option', '-w', '-t', pane, '@claude', flag])
}

async function isAgentBusy($: EngineInterface): Promise<boolean> {
  const agents = await $.agent.list()
  return agents.some(agent => BUSY_AGENT_STATUSES.has(agent.status))
}

async function startAsking($: EngineInterface, toolUseId: string): Promise<void> {
  if (askingToolUseIds.has(toolUseId)) return
  askingToolUseIds.add(toolUseId)
  await raiseFlag($, 'ask')
}

async function stopAsking($: EngineInterface, toolUseId: string): Promise<void> {
  if (!askingToolUseIds.delete(toolUseId) || askingToolUseIds.size > 0) return
  await clearFlag($)
}

export const register: Register = on => {
  on('prompt.submit', async ($, e, next) => {
    const isFromUser = e.origin.kind === 'composer' || e.origin.kind === 'bridge'
    const startsTurn = e.turnId === undefined
    if (startsTurn) isWakeUp = e.origin.kind === 'task-notification'
    if (isFromUser || (startsTurn && !isWakeUp)) promptedAt = await $.clock.now()
    if (isFromUser) {
      askingToolUseIds.clear()
      await clearFlag($)
    }
    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    try {
      if (e.agentId === undefined && (e.tool === 'AskUserQuestion' || e.tool === 'ExitPlanMode')) await startAsking($, e.tool_use_id)
      return await next(e)
    } finally {
      await stopAsking($, e.tool_use_id)
    }
  })

  on('turn.complete', async ($, e, next) => {
    if (e.agentId === undefined) {
      const wasWakeUp = isWakeUp
      isWakeUp = false
      if (!e.isAborted) {
        const elapsedMs = wasWakeUp && promptedAt !== undefined ? (await $.clock.now()) - promptedAt : e.durationMs
        if (elapsedMs >= DONE_AFTER_MS && !(await isAgentBusy($))) await raiseFlag($, 'done')
      }
    }
    return next(e)
  })
}
