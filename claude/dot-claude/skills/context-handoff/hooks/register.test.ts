import type { On } from 'claude-code'
import type { Engine } from 'claude-code/testing'
import { describe, expect, test } from 'claude-code/testing'

const THRESHOLD = 167_000

function fakeSession(on: On, tokens: number): unknown[] {
  const notes: unknown[] = []
  on('session.usage', ($, e) => ({
    value: {
      startedAt: 0,
      rateLimits: [],
      context: {
        window: 200_000,
        breakdown: e.breakdown === undefined ? undefined : ({ totalTokens: tokens, autoCompactThreshold: THRESHOLD } as never),
      },
    },
  }))
  on('session.append', ($, e) => {
    notes.push(e.message.content)
    return { message: e.message, uuid: `n${notes.length}` }
  })
  on('turn.step', async function* ($, e) {
    return { turnId: e.turnId, index: e.index, answer: '', toolUses: [], stopReason: 'end_turn', usage: null }
  })
  return notes
}

async function stepped($: Engine, agentId?: string): Promise<void> {
  const stream = $.turn.step({ turnId: 't1', index: 0, model: 'claude-opus-5-5', messageCount: 1, agentId })
  for await (const _chunk of stream) { /* drain */ }
}

describe('context-handoff', () => {
  test('below the warn level nothing is appended', async ($, on) => {
    const notes = fakeSession(on, 140_000)
    await stepped($)
    expect(notes).toEqual([])
  })

  test('a subagent step never warns', async ($, on) => {
    const notes = fakeSession(on, 160_000)
    await stepped($, 'a1')
    expect(notes).toEqual([])
  })
})
