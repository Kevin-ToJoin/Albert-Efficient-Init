# Project rules (Albert-Efficient-Init, local-only)

This file and the `Efficiency/` folder are gitignored. They reflect the local
developer's preferences and do not affect collaborators.

## Base rules

- Read existing files before writing. Do not re-read a file in the same
  session unless it may have changed.
- Concise output, thorough reasoning. Brief is good; silent is not.
- No sycophantic openers, no closing fluff, no restating of the question.
- No em-dashes or decorative Unicode. Plain hyphens and straight quotes only.
- Never invent APIs, flags, versions, paths, commit SHAs, or package names.
  Verify by reading code or documentation before asserting.
- Skip files over 100KB unless the task requires them.
- User instructions always override these rules. If asked for a long
  explanation, give one.

## Profiles

Read the matching profile only if the task calls for it:

- `Efficiency/rules-coding.md` for development, code review, debugging, and
  refactoring tasks.
- `Efficiency/rules-analysis.md` for data analysis, research, and reporting
  tasks.

If the task is mixed or unclear, ask which profile to use rather than
guessing.
