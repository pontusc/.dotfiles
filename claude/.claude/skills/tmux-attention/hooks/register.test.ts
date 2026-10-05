import type { Engine, On } from 'claude-code/testing'
import { describe, expect, mock, test } from 'claude-code/testing'

const UNWATCHED = '1\t0\t1\twork'
const WATCHED = '1\t1\t1\twork'

function fakeTmux(on: On, display: string): string[][] {
  const calls: string[][] = []
  on('process.run', ($, e) => {
    calls.push([...e.argv])
    const stdout = e.argv[1] === 'display' ? display : e.argv[1] === 'list-clients' ? 'attached,focused\n' : ''
    return { value: { exitCode: 0, stdout, stderr: '' } }
  })
  on('tool.check', () => ({ decision: 'ask' }))
  on('tool.call', () => ({ result: 'ok' }))
  on('prompt.submit', ($, e) => ({ text: e.text }))
  on('turn.complete', () => ({ text: '' }))
  return calls
}

function flagWrites(calls: string[][]): string[][] {
  return calls.filter(argv => argv[1] === 'set-option')
}

async function permissionAsked($: Engine): Promise<void> {
  await $.tool.check({ tool: 'Bash', input: { command: 'ls' }, tool_use_id: 't1' })
}

async function turnEnded($: Engine, durationMs: number, agentId?: string): Promise<void> {
  await $.turn.complete({ answer: '', durationMs, isAborted: false, turnId: 'u1', reason: 'answer', agentId })
}

async function prompted($: Engine, kind: 'composer' | 'task-notification'): Promise<void> {
  await $.prompt.submit({ text: 'go', wait: false, origin: { kind } })
}

const ASK = ['tmux', 'set-option', '-w', '-t', '%7', '@claude', 'ask']
const DONE = ['tmux', 'set-option', '-w', '-t', '%7', '@claude', 'done']
const CLEAR = ['tmux', 'set-option', '-w', '-t', '%7', '-u', '@claude']

describe('tmux-attention', () => {
  test('a permission prompt flags an unwatched pane ask', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await permissionAsked($)
    expect(flagWrites(calls)).toEqual([ASK])
  })

  test('a permission query outside a real call flags nothing', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await $.tool.check({ tool: 'Bash', input: { command: 'ls' } })
    expect(calls).toEqual([])
  })

  test('a watched pane is never flagged', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, WATCHED)
    await permissionAsked($)
    expect(flagWrites(calls)).toEqual([])
  })

  test('outside tmux nothing runs', async ($, on) => {
    mock.env(on, {})
    const calls = fakeTmux(on, UNWATCHED)
    await permissionAsked($)
    expect(calls).toEqual([])
  })

  test('a long main turn flags done, a short or subagent one does not', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await turnEnded($, 10_000)
    await turnEnded($, 21_000, 'a1')
    await $.turn.complete({ answer: '', durationMs: 21_000, isAborted: true, turnId: 'u1', reason: 'aborted' })
    expect(flagWrites(calls)).toEqual([])
    await turnEnded($, 21_000)
    expect(flagWrites(calls)).toEqual([DONE])
  })

  test('a question flags ask until it is answered', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await $.tool.call({ tool: 'AskUserQuestion', questions: [] })
    expect(flagWrites(calls)).toEqual([ASK, CLEAR])
  })

  test('a main turn ending clears a pending ask', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await permissionAsked($)
    await turnEnded($, 1_000, 'a1')
    expect(flagWrites(calls)).toEqual([ASK])
    await turnEnded($, 1_000)
    expect(flagWrites(calls)).toEqual([ASK, CLEAR])
  })

  test('another tool finishing leaves a pending ask', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await permissionAsked($)
    await $.tool.call({ tool: 'Read', file_path: '/etc/hostname' })
    expect(flagWrites(calls)).toEqual([ASK])
  })

  test('only the user clears done, once', async ($, on) => {
    mock.env(on, { TMUX_PANE: '%7' })
    const calls = fakeTmux(on, UNWATCHED)
    await turnEnded($, 21_000)
    await prompted($, 'task-notification')
    expect(flagWrites(calls)).toEqual([DONE])
    await prompted($, 'composer')
    await prompted($, 'composer')
    expect(flagWrites(calls)).toEqual([DONE, CLEAR])
  })
})
