# Coding profile

Applies on top of the base rules in the project root `CLAUDE.md`.

## Output

- Code first. Explanation only if the logic is non-obvious or the user asks.
- No boilerplate unless requested.
- Do not add comments, docstrings, or type annotations to code that is not
  being changed.

## Code style

- Simplest working solution. No abstraction for single-use logic.
- Three similar lines is better than a premature helper function.
- No speculative features.
- Read the file before editing it.
- No error handling for cases that cannot occur. Validate at boundaries
  (user input, external APIs), trust internal calls.

## Code review

- State the bug. Show the fix. Stop.
- No suggestions outside the scope of the change.
- No compliments before or after the review.

## Debugging

- Read the relevant code before forming a hypothesis.
- Report what was found, where, and the fix. One pass.
- If the cause is unclear, say so. Do not guess at a fix.

## When refactoring

- Only refactor what was requested. Do not bundle drive-by cleanups.
- Preserve behavior unless the user asked for a behavior change.
