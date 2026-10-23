import type { Engine, On } from 'claude-code/testing'
import { describe, expect, test } from 'claude-code/testing'

const DENIAL = (code: string): string =>
  `BLOCKED by dcg\n\nTo permit this single command once, the user can approve it with: dcg allow-once ${code}`

type Outcome = { deny: string } | { result: string; text?: string; isError?: boolean }

function fakeEngine(on: On, outcomes: Outcome[]): string[] {
  const suggestions: string[] = []
  on('tool.call', () => outcomes.shift() ?? { result: 'ok' })
  on('turn.complete', () => ({ text: '' }))
  on('prompt.suggest', ($, e) => {
    suggestions.push(e.text)
    return { isShown: true }
  })
  return suggestions
}

async function bashRan($: Engine, agentId?: string): Promise<void> {
  await $.tool.call({ tool: 'Bash', command: 'rm -rf ~/foo', agentId })
}

async function turnEnded($: Engine, options: { agentId?: string; isAborted?: boolean } = {}): Promise<void> {
  const isAborted = options.isAborted ?? false
  await $.turn.complete({
    answer: '',
    durationMs: 1_000,
    isAborted,
    turnId: 'u1',
    reason: isAborted ? 'aborted' : 'answer',
    agentId: options.agentId,
  })
}

describe('dcg-approve', () => {
  test('a turn without a block suggests nothing', async ($, on) => {
    const suggestions = fakeEngine(on, [{ result: 'ok' }])
    await bashRan($)
    await turnEnded($)
    expect(suggestions).toEqual([])
  })

  test('a main turn suggests the last blocked code', async ($, on) => {
    const suggestions = fakeEngine(on, [{ deny: DENIAL('111111') }, { result: 'ok' }, { deny: DENIAL('222222') }])
    await bashRan($)
    await bashRan($)
    await bashRan($)
    await turnEnded($)
    expect(suggestions).toEqual(['! dcg allow-once -y 222222'])
  })

  test('a subagent block is offered when the main turn ends', async ($, on) => {
    const suggestions = fakeEngine(on, [{ deny: DENIAL('333333') }])
    await bashRan($, 'a1')
    await turnEnded($, { agentId: 'a1' })
    expect(suggestions).toEqual([])
    await turnEnded($)
    expect(suggestions).toEqual(['! dcg allow-once -y 333333'])
  })

  test('a hook error result carries the code', async ($, on) => {
    const suggestions = fakeEngine(on, [{ result: '', text: `PreToolUse:Bash hook error: ${DENIAL('555555')}`, isError: true }])
    await bashRan($)
    await turnEnded($)
    expect(suggestions).toEqual(['! dcg allow-once -y 555555'])
  })

  test('a code in successful or non shell output is ignored', async ($, on) => {
    const suggestions = fakeEngine(on, [
      { result: '', text: DENIAL('666666'), isError: false },
      { result: '', text: DENIAL('777777'), isError: true },
    ])
    await bashRan($)
    await $.tool.call({ tool: 'Read', file_path: 'transcript.jsonl' })
    await turnEnded($)
    expect(suggestions).toEqual([])
  })

  test('an aborted turn suggests nothing and forgets the code', async ($, on) => {
    const suggestions = fakeEngine(on, [{ deny: DENIAL('444444') }])
    await bashRan($)
    await turnEnded($, { isAborted: true })
    await turnEnded($)
    expect(suggestions).toEqual([])
  })
})
