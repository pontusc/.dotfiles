---
name: lua
description: Lua / Neovim plugin conventions, applied when writing or editing .lua files, Neovim plugins, or Neovim config.
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# Lua / Neovim Plugin Conventions

Apply when writing or editing `.lua` files: Neovim plugins, config, or scripts.
The normative source for plugin structure is Neovim's own guide: `:h lua-plugin`
(shipped since 0.11, at `$VIMRUNTIME/doc/lua-plugin.txt`). When in doubt, read it,
don't recall it.

## Scope of changes (read first)

- **Stay surgical.** Match the file's existing style, module pattern, and comment
  density. A fix applies to the lines you're changing: don't restructure modules or
  retrofit these conventions into code you weren't asked to touch.
- **Suggest, don't migrate.** If an existing plugin diverges (mandatory `setup()`,
  many top-level commands), note it: migrate only when explicitly asked.
- **Verify, don't recall.** Neovim/plugin runtime behavior is checked empirically
  (headless `nvim --clean` snippets, installed plugin docs), never asserted from memory.

## Plugin structure (the lua-plugin rules)

- **`plugin/<name>.lua` is the entrypoint, `setup()` is optional.** The plugin works
  out of the box: commands, `<Plug>` mappings, and autocmds are registered eagerly in
  `plugin/`, guarded by `if vim.g.loaded_<name> then return end`.
- **Defer every `require`.** `plugin/` scripts and mapping/command callbacks
  `require` inside the callback, never at script top level. Module-to-module requires
  inside functions keep load graphs lazy. Plugins arrange their own laziness: users
  should not need `lazy = false` gymnastics or `cmd=`/`keys=` stubs.
- **Config ≠ initialization.** `setup(opts)` only merges overrides. Also accept a
  Vimscript-compatible `vim.g.<name>` table. Merge `defaults < vim.g.<name> <
  setup(opts)` via `vim.tbl_deep_extend("force", vim.deepcopy(defaults), …)`.
- **One namespaced command** (`:Name sub`) with a `complete` function, not N
  top-level commands. Expose actions as `<Plug>(NameAction)` mappings. Ship default
  binds only buffer-locally (review/UI buffers), mapping the configured lhs onto the
  `<Plug>` action (a `<Plug>` rhs is expanded even under noremap).
- **Fire `User` autocmd events** at lifecycle/data-mutation points
  (`nvim_exec_autocmds("User", { pattern = "NameThing", data = …, modeline = false })`):
  they are the extension surface. Document the catalogue.
- **Never clobber another plugin's global setup.** Scope integration config
  buffer-locally (`vim.b.<plugin>_config`, mini.nvim style: `vim.b` holds tables
  containing functions) and call the other plugin's `setup()` only when the user
  hasn't (`rawget(_G, "PluginGlobal") == nil`).
- **Autocmds live in owned augroups with a defined lifetime.** Feature-scoped groups
  are created on activation and deleted on teardown: the plugin idles at zero cost.
  Global autocmds registered from a transient UI are released on every close path
  (plus a `return true` self-delete fallback in the callback).

## Code style

- LuaCATS annotations throughout: `---@class`/`---@field` for config and opts tables,
  `---@param`/`---@return` on public functions. Typed config gives users completion
  and lua-ls the ability to catch bugs in CI.
- Validate merged config: `vim.validate` (0.11+ form: `vim.validate(name, value,
  validator)`) for types at first use. Unknown-key (typo) detection belongs in
  `:checkhealth`, not the hot path.
- Doc comments state *why* and the invariant, not what the next line does. Module
  headers say what the module owns and what it deliberately does not.
- State model: one authoritative store. UI artifacts (extmarks, windows, lines) are
  pure view: rebuilt from the store, never read back as truth.
- `lua/<name>/init.lua` stays a thin façade. One concern per module. Reusable UI
  widgets (input floats etc.) take a single opts table and know nothing about callers.
- Errors to users via `vim.notify("<name>: …", vim.log.levels.X)`, prefixed with the
  plugin name. `pcall` only where failure is expected and handled.

## Health & docs

- `lua/<name>/health.lua` checks: Neovim version, external binaries, Lua/plugin
  deps, and config validity.
- Vimdoc (`doc/<name>.txt`) and README cover the same surface and are updated in the
  same change as the code: stale docs are a defect.

## Testing

- Headless suites: `nvim --headless --clean --cmd 'set rtp+=. rtp+=<dep>' -l
  tests/x.lua`, real (pinned, gitignored) plugin deps, assert-count summary, exit
  `qa!`/`cq!` on pass/fail. Note `-l` may skip `plugin/` sourcing: tests source it
  explicitly (`runtime! plugin/<name>.lua`, and the loaded-guard makes it idempotent).
- Monkeypatch at module seams (`require("x.mod").fn = stub`): design seams so UI
  (floats, prompts) is replaceable by a function call in tests.
- Interactive behavior (mouse, focus, resize) is verified against an embedded child:
  `jobstart({"nvim","--embed","--clean"}, {rpc=true})` + `nvim_ui_attach(w, h,
  vim.empty_dict())`, driven over `rpcrequest`.

## Quality gate

Both must pass on `lua/` and `plugin/` (CI and locally):

```
stylua --check lua plugin
lua-language-server --check=lua --check_format=pretty --configpath=.luarc.json
```
