---
name: load-context
description: Read one or more files from any path and pull their contents into the conversation for reference.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Bash
argument-hint: <path> [path2] [path3...]
---

Read the specified files and add their contents to the conversation context.

Arguments: $ARGUMENTS

For each argument:

1. If the path is a file, read it in full.
2. If the path is a directory, list its contents and read any README or documentation files inside it.
3. If the path contains a glob pattern (e.g. `~/.config/**/*.toml`), expand it and read matching files.
4. Expand `~` to the user's home directory.

After reading, provide a brief summary of what was loaded (file names, line counts) so the user knows what's now in context. Do not editorialize on the file contents unless asked.
