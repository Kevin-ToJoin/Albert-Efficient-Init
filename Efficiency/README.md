# Efficiency/

Local rule profiles loaded by Claude Code when the task matches.

This folder is gitignored in the host project. Files here only affect the
local developer. They are installed by `Albert-Efficient-Init/install.sh`.

## Files

- `rules-coding.md` -> development, code review, debugging.
- `rules-analysis.md` -> data analysis, research, reporting.

## How they are activated

The project root `CLAUDE.md` (also gitignored) instructs Claude to read the
matching profile when the task calls for it. You can also reference a
profile explicitly in a prompt:

> "Apply the coding profile and review this function."

## Adding a custom profile

Drop a new `rules-<name>.md` file here. Then update the project root
`CLAUDE.md` to list it under the Profiles section.

## Removing

Delete the file. The base rules in the project root `CLAUDE.md` still apply.
