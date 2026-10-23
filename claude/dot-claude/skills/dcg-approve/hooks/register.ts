import type { Register } from 'claude-code'

const DCG_TOOLS: ReadonlySet<string> = new Set(['Bash', 'PowerShell', 'Monitor'])
const DENIAL_CODE = /approve it with: dcg allow-once (\d+)$/m

let blockedCode: string | undefined

export const register: Register = on => {
  on('tool.call', async ($, e, next) => {
    const outcome = await next(e)
    if (!DCG_TOOLS.has(e.tool)) return outcome
    const denial = 'deny' in outcome ? outcome.deny : outcome.isError ? outcome.text : undefined
    const code = denial?.match(DENIAL_CODE)?.[1]
    if (code !== undefined) blockedCode = code
    return outcome
  })

  on('turn.complete', async ($, e, next) => {
    const completed = await next(e)
    if (e.agentId === undefined) {
      if (!e.isAborted && blockedCode !== undefined) {
        void $.prompt.suggest({ text: `! dcg allow-once -y ${blockedCode}` })
      }
      blockedCode = undefined
    }
    return completed
  })
}
