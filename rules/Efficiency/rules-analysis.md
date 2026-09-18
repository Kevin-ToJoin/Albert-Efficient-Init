# Analysis profile

Applies on top of the base rules in the project root `CLAUDE.md`.

## Output

- Lead with the finding. Context and methodology after.
- Tables and bullets over prose paragraphs.
- Numbers must include units. Never ambiguous values.

## Accuracy

- Every number needs a source or a derivation.
- If data is missing, say so. Do not estimate silently.
- If confidence is low, state it and explain why.
- Preserve meaningful precision. Do not round aggressively when precision
  matters.

## No fabrication

- Do not invent data points, statistics, citations, or sources.
- A claim that cannot be grounded in provided data must not be made.
- Label inferences explicitly. "Based on the trend..." rather than stating
  the inference as fact.

## Report shape

- Summary first (three bullets maximum).
- Supporting data second.
- Caveats and limitations last.
- No narrative filler between sections.

## When the question is ambiguous

- Ask before assuming the scope or definition.
- Do not produce a plausible-looking answer to a question you have not
  fully understood.
