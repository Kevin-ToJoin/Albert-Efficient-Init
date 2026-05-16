# Attribution

This project takes ideas (not verbatim text) from:

**claude-token-efficient** by Drona Gangarapu
Repository: https://github.com/drona23/claude-token-efficient
License: MIT

## What was reused

- The general concept of a project-level rule file consumed by Claude Code.
- The categorization of failure modes (sycophancy, verbose preambles, em-dashes, invented APIs).
- The idea of splitting profiles by task type (coding, analysis).

## What is original here

- Local-only install model: files live in a gitignored `Efficiency/` folder so collaborators are not affected.
- Idempotent `install.sh` that wires up `.gitignore` and the root entry-point.
- All rule wording is rewritten. No paragraph or rule was copied verbatim.
- Removed: marketing claims, benchmark tables, agents profile, versioned configuration sets, decorative content.
- Reframed: rules are stated as actions rather than prohibitions wherever possible.

## License compatibility

Both projects are MIT-licensed. The MIT license requires that the original copyright notice and license text be preserved when substantial portions are reused. Since no verbatim text was reused, attribution here is offered as good practice rather than a strict legal requirement.

## Original MIT notice (preserved as courtesy)

```
MIT License

Copyright (c) 2026 Drona Gangarapu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

Full original license available at the source repository.
