import type { Register } from 'claude-code'

const WARN_AT_SHARE_OF_THRESHOLD = 0.9

let hasWarned = false

function handoffNote(tokens: number, threshold: number): string {
  return [
    `Context is at ${tokens} of the ${threshold} tokens where auto-compact runs.`,
    'Do not stop early or cut corners. Bring the work to a coherent state, then write HANDOFF.md in the working directory for a fresh session:',
    'the original request verbatim, what is done, what is in progress, next steps, decisions made and why, and what has been verified and how.',
    'Then end your turn and tell the user to run /clear and point the new session at HANDOFF.md.',
  ].join(' ')
}

export const register: Register = on => {
  on('turn.step', async function* ($, e, next) {
    if (e.agentId === undefined) {
      const { breakdown } = (await $.session.usage({ breakdown: 'summary' })).context
      const tokens = breakdown?.totalTokens
      const threshold = breakdown?.autoCompactThreshold
      if (tokens !== undefined && threshold !== undefined) {
        const isPastWarnLevel = tokens >= threshold * WARN_AT_SHARE_OF_THRESHOLD
        if (isPastWarnLevel && !hasWarned) {
          await $.session.append({ message: { type: 'user', content: [{ type: 'text', text: handoffNote(tokens, threshold) }] } })
        }
        hasWarned = isPastWarnLevel
      }
    }
    return yield* next(e)
  })
}
