---
name: lua
description: Lua / Neovim plugin conventions, applied when writing or editing .lua files, Neovim plugins, or Neovim config.
user-invocable: false
allowed-tools: Read, Glob, Grep
paths:
  - "**/*.lua"
---

# Lua and Neovim Plugin Conventions

`:h lua-plugin`, shipped since 0.11 at `$VIMRUNTIME/doc/lua-plugin.txt`, is the normative source for plugin structure. Read it rather than recalling it.

## Plugin structure

- `plugin/<name>.lua` is the entrypoint and `setup()` is optional. Commands, `<Plug>` mappings, and autocmds register eagerly there, guarded by `if vim.g.loaded_<name> then return end`.
- Defer every `require` into the callback that needs it, never at script top level, module to module included. A plugin arranges its own laziness, so users need no `lazy = false`, `cmd=`, or `keys=` stubs.
- `setup(opts)` merges overrides only. Also accept a Vimscript-compatible `vim.g.<name>` table, merging `defaults < vim.g.<name> < setup(opts)` with `vim.tbl_deep_extend("force", vim.deepcopy(defaults), ...)`.
- One namespaced command (`:Name sub`) with a `complete` function instead of N top-level commands. Actions are exposed as `<Plug>(NameAction)` mappings. Default binds ship buffer-locally only, for review and UI buffers, mapping the configured lhs onto the `<Plug>` action, which expands even under noremap.
- Fire `User` events at lifecycle and data-mutation points with `nvim_exec_autocmds("User", { pattern = "NameThing", data = ..., modeline = false })` and document the catalogue. They are the extension surface.
- Never clobber another plugin's global setup. Scope integration config buffer-locally in `vim.b.<plugin>_config`, mini.nvim style where `vim.b` holds tables containing functions, and call the other plugin's `setup()` only when the user has not (`rawget(_G, "PluginGlobal") == nil`).
- Autocmds live in owned augroups, feature-scoped, created on activation and deleted on teardown. Global autocmds from a transient UI are released on every close path, with a `return true` self-delete fallback in the callback.
- Validate merged config at first use with `vim.validate(name, value, validator)`, the 0.11 form. Unknown-key detection belongs in `:checkhealth`, not the hot path.

## Health, docs, tests

- `lua/<name>/health.lua` checks Neovim version, external binaries, Lua and plugin deps, and config validity.
- `doc/<name>.txt` and the README cover the same surface and change together with the code.
- Headless suites: `nvim --headless --clean --cmd 'set rtp+=. rtp+=<dep>' -l tests/x.lua` against pinned, gitignored plugin deps, with an assert-count summary and `qa!` or `cq!` on pass or fail. `-l` may skip `plugin/` sourcing, so tests run `runtime! plugin/<name>.lua`, which the loaded guard makes idempotent.
- LuaCATS annotations: `---@class` and `---@field` on config and opts tables, `---@param` and `---@return` on public functions.
- Verify interactive behavior (mouse, focus, resize) against an embedded child: `jobstart({"nvim","--embed","--clean"}, {rpc=true})` plus `nvim_ui_attach(w, h, vim.empty_dict())`, driven over `rpcrequest`.

## Before reporting

- Both pass: `stylua --check lua plugin` and `lua-language-server --check=lua --check_format=pretty --configpath=.luarc.json`.
- No `require` at the top level of a `plugin/` script or a module.
- Vimdoc and README match the code surface in this change.
