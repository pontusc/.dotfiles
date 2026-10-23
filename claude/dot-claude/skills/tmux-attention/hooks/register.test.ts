import type { AgentStatus } from 'claude-code'
import type { Engine, MockClock, On } from 'claude-code/testing'
import { describe, expect, mock, test } from 'claude-code/testing'

const UNWATCHED = '1\t0\t1\twork'
const WATCHED = '1\t1\t1\twork'

function fakeTmux(
  on: On,
  display: string,
  agentStatuses: AgentStatus[] = [],
  runTool: () => { result: string } = () => ({ result: 'ok' }),
): string[][] {
  const calls: string[][] = []
  on('agent.list', () => ({
    value: agentStatuses.map((status, i) => ({ id: `a${i}`, description: '', type: 'Explore', status })),
  }))
  on('process.run', ($, e) => {
    calls.push([...e.argv])
    const stdout = e.argv[1] === 'display' ? display : e.argv[1] === 'list-clients' ? 'attached,focused\n' : ''
    return { value: { exitCode: 0, stdout, stderr: '' } }
  })
  on('tool.call', runTool)
  on('prompt.submit', ($, e) => ({ text: e.text }))
  on('turn.complete', () => ({ text: '' }))
  return calls
}

function flagWrites(calls: string[][]): string[][] {
  return calls.filter(argv => argv[1] === 'set-option')
}

async function questionAsked($: Engine): Promise<void> {
  await $.tool.call({ tool: 'AskUserQuestion', questions: [] })
}

async function turnEnded($: Engine, durationMs: number, agentId?: string): Promise<void> {
  await $.turn.complete({ answer: '', durationMs, isAborted: false, turnId: 'u1', reason: 'answer', agentId })
}

async function workedFor($: Engine, clock: MockClock, ms: number, agentId?: string): Promise<void> {
  await clock.advance(ms)
  await turnEnded($, ms, agentId)
}

async function prompted(
  $: Engine,
  kind: 'composer' | 'task-notification' | 'scheduled-trigger' | 'peer',
  turnId?: string,
): Promise<void> {
  await $.prompt.submit({ text: 'go', wait: false, origin: { kind }, turnId })
}

const ASK = ['tmux', 'set-option', '-w', '-t', '%7', '@claude', 'ask']
const DONE = ['tmux', 'set-option', '-w', '-t', '%7', '@claude', 'done']
const CLEAR = ['tmux', 'set-option', '-w', '-t', '%7', '-u', '@claude']

describe('tmux-attention', () => {
  test('a tool other than a question or plan flags nothing', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await $.tool.call({ tool: 'Bash', command: 'ls' })
    expect(calls).toEqual([])
  })

  test('a watched pane is never flagged', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, WATCHED)
    await questionAsked($)
    expect(flagWrites(calls)).toEqual([])
  })

  test('outside tmux nothing runs', async ($, on) => {
    mock.env(on, {})
    const calls = fakeTmux(on, UNWATCHED)
    await questionAsked($)
    expect(calls).toEqual([])
  })

  test('a long main turn flags done, a short, subagent or aborted one does not', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await turnEnded($, 10_000)
    await turnEnded($, 21_000, 'a1')
    await $.turn.complete({ answer: '', durationMs: 21_000, isAborted: true, turnId: 'u1', reason: 'aborted' })
    expect(flagWrites(calls)).toEqual([])
    await turnEnded($, 21_000)
    expect(flagWrites(calls)).toEqual([DONE])
  })

  test('a main turn waiting on busy agents flags nothing', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const clock = mock.clock(on)
    const calls = fakeTmux(on, UNWATCHED, ['running', 'pending', 'waiting', 'completed'])
    await prompted($, 'composer')
    await workedFor($, clock, 21_000)
    expect(flagWrites(calls)).toEqual([])
  })

  test('the short wake up turn after a long prompt flags done', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const clock = mock.clock(on)
    const calls = fakeTmux(on, UNWATCHED, ['completed', 'idle'])
    await prompted($, 'composer')
    await clock.advance(30_000)
    await prompted($, 'task-notification')
    await workedFor($, clock, 1_000)
    expect(flagWrites(calls)).toEqual([DONE])
  })

  test('a short scheduled turn long after the prompt flags nothing', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const clock = mock.clock(on)
    const calls = fakeTmux(on, UNWATCHED)
    await prompted($, 'composer')
    await clock.advance(30_000)
    await prompted($, 'scheduled-trigger')
    await workedFor($, clock, 1_000)
    expect(flagWrites(calls)).toEqual([])
  })

  test('a short turn after a wake up turn flags nothing', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const clock = mock.clock(on)
    const calls = fakeTmux(on, UNWATCHED)
    await prompted($, 'composer')
    await clock.advance(30_000)
    await prompted($, 'task-notification')
    await workedFor($, clock, 1_000)
    expect(flagWrites(calls)).toEqual([DONE])
    await prompted($, 'scheduled-trigger')
    await workedFor($, clock, 1_000)
    expect(flagWrites(calls)).toEqual([DONE])
  })

  test('a short unprompted turn after a wake up turn flags nothing', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const clock = mock.clock(on)
    const calls = fakeTmux(on, UNWATCHED)
    await prompted($, 'composer')
    await clock.advance(30_000)
    await prompted($, 'task-notification')
    await workedFor($, clock, 1_000)
    expect(flagWrites(calls)).toEqual([DONE])
    await workedFor($, clock, 1_000)
    expect(flagWrites(calls)).toEqual([DONE])
  })

  test('a notification delivered into a short unprompted turn flags nothing', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const clock = mock.clock(on)
    const calls = fakeTmux(on, UNWATCHED)
    await prompted($, 'composer')
    await clock.advance(30_000)
    await prompted($, 'task-notification', 'u1')
    await workedFor($, clock, 1_000)
    expect(flagWrites(calls)).toEqual([])
  })

  test('a peer message delivered into a wake up turn still flags done', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const clock = mock.clock(on)
    const calls = fakeTmux(on, UNWATCHED)
    await prompted($, 'composer')
    await clock.advance(30_000)
    await prompted($, 'task-notification')
    await prompted($, 'peer', 'u1')
    await workedFor($, clock, 1_000)
    expect(flagWrites(calls)).toEqual([DONE])
  })

  test('a wake up turn counts from the scheduled turn that started the work', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const clock = mock.clock(on)
    const calls = fakeTmux(on, UNWATCHED)
    await prompted($, 'composer')
    await clock.advance(3_600_000)
    await prompted($, 'scheduled-trigger')
    await workedFor($, clock, 2_000)
    await clock.advance(5_000)
    await prompted($, 'task-notification')
    await workedFor($, clock, 1_000)
    expect(flagWrites(calls)).toEqual([])
  })

  test('a subagent question or plan flags nothing', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await $.tool.call({ tool: 'AskUserQuestion', questions: [], agentId: 'a1' })
    await $.tool.call({ tool: 'ExitPlanMode', plan: '', agentId: 'a1' })
    expect(calls).toEqual([])
  })

  test('a failed ask write does not block the next question', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls: string[][] = []
    let isFirstAsk = true
    on('agent.list', () => ({ value: [] }))
    on('process.run', ($, e) => {
      calls.push([...e.argv])
      if (e.argv.at(-1) === 'ask' && isFirstAsk) {
        isFirstAsk = false
        throw new Error('tmux gone')
      }
      const stdout = e.argv[1] === 'display' ? UNWATCHED : e.argv[1] === 'list-clients' ? 'attached,focused\n' : ''
      return { value: { exitCode: 0, stdout, stderr: '' } }
    })
    on('tool.call', () => ({ result: 'ok' }))
    await questionAsked($).catch(() => undefined)
    await questionAsked($)
    expect(flagWrites(calls)).toEqual([ASK, CLEAR, ASK, CLEAR])
  })

  test('a call that throws does not leave its ask behind', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED, [], () => {
      throw new Error('aborted')
    })
    await questionAsked($).catch(() => undefined)
    expect(flagWrites(calls)).toEqual([ASK, CLEAR])
  })

  test('a question or plan flags ask until it is answered', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await questionAsked($)
    await $.tool.call({ tool: 'ExitPlanMode', plan: '' })
    expect(flagWrites(calls)).toEqual([ASK, CLEAR, ASK, CLEAR])
  })

  test('only the user clears done, once', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const clock = mock.clock(on)
    const calls = fakeTmux(on, UNWATCHED)
    await prompted($, 'composer')
    await workedFor($, clock, 21_000)
    await prompted($, 'task-notification')
    expect(flagWrites(calls)).toEqual([DONE])
    await prompted($, 'composer')
    await prompted($, 'composer')
    expect(flagWrites(calls)).toEqual([DONE, CLEAR])
  })
})
