# Albert-Efficient-Init

Local-only rule files for Claude Code that keep responses concise and prevent
the common failure modes (sycophancy, verbosity, invented APIs). Drop into
any project. The files are auto-added to that project's `.gitignore` so they
only affect your local sessions and never reach your collaborators.

## What it gives you

After running the installer in a target project you get:

```
your-project/
  CLAUDE.md              # gitignored, entry point Claude reads automatically
  Efficiency/            # gitignored, expanded profiles
    rules-coding.md
    rules-analysis.md
    README.md
  .gitignore             # tracked, gets two new lines appended
```

Claude reads `CLAUDE.md` on every turn and pulls the matching profile from
`Efficiency/` when the task calls for it.

Nothing leaks to collaborators. The two paths are added to the project
`.gitignore`.

## Install

### Linux / macOS (bash)

From inside any target project directory:

```bash
bash /path/to/Albert-Efficient-Init/install.sh
```

Or pass an explicit target:

```bash
bash /path/to/Albert-Efficient-Init/install.sh /path/to/target/project
```

### Windows (PowerShell)

From inside any target project directory:

```powershell
powershell -ExecutionPolicy Bypass -File C:\path\to\Albert-Efficient-Init\install.ps1
```

Or pass an explicit target:

```powershell
powershell -ExecutionPolicy Bypass -File C:\path\to\Albert-Efficient-Init\install.ps1 -Target C:\path\to\target\project
```

### One-liner directly from GitHub (no clone needed)

> Replace `<USER>` with the GitHub user/org hosting this repo and `<BRANCH>`
> with the branch (usually `main`).

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/<USER>/Albert-Efficient-Init/<BRANCH>/install.sh | bash
```

This grabs only the installer script. Because the installer also needs the
template files, a clone-then-install flow is the most reliable. The full one
liner:

```bash
git clone --depth 1 https://github.com/<USER>/Albert-Efficient-Init /tmp/aei && bash /tmp/aei/install.sh
```

**Windows:**

```powershell
git clone --depth 1 https://github.com/<USER>/Albert-Efficient-Init $env:TEMP\aei; powershell -ExecutionPolicy Bypass -File $env:TEMP\aei\install.ps1
```

### Idempotency

Re-running the installer does not overwrite an existing `CLAUDE.md` and does
not duplicate `.gitignore` entries. It is safe to re-run after pulling
updates.

## What's in it

- `CLAUDE-root-template.md` -> installs as project root `CLAUDE.md`. Contains
  the base rules.
- `Efficiency/rules-coding.md` -> dev work, code review, debugging.
- `Efficiency/rules-analysis.md` -> data analysis, reporting, research.

The base rules are always active. Profiles are only loaded when the task
matches.

## Update an installed project

Re-run the installer from the target. New profile files get copied in;
existing files are preserved. To force-refresh, delete `Efficiency/` first
and re-run.

## Uninstall

### Linux / macOS

```bash
bash /path/to/Albert-Efficient-Init/uninstall.sh
# or against an explicit target:
bash /path/to/Albert-Efficient-Init/uninstall.sh /path/to/target/project
```

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File C:\path\to\Albert-Efficient-Init\uninstall.ps1
# or against an explicit target:
powershell -ExecutionPolicy Bypass -File C:\path\to\Albert-Efficient-Init\uninstall.ps1 -Target C:\path\to\target\project
```

The uninstaller removes `CLAUDE.md`, removes `Efficiency/`, and strips the
matching block from the project `.gitignore`.

## Why local-only

The rules reflect personal preferences. Forcing them on collaborators
creates friction. Keeping the files gitignored means each developer can pick
their own setup.

## For forks, merges, cherry-picks

If you bring these files into another repository via fork, merge, or
cherry-pick, run the installer once in that target repo. The installer
appends the two paths to that repo's `.gitignore` so the files only act as
local guides and never travel further with your commits.

## Attribution

Derived from ideas in
[drona23/claude-token-efficient](https://github.com/drona23/claude-token-efficient)
(MIT). See [ATTRIBUTION.md](ATTRIBUTION.md).

## License

MIT. See [LICENSE](LICENSE).
