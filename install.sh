#!/usr/bin/env bash
#
# Albert-Efficient-Init installer
#
# Copies the rule files into a target project, wires up the root CLAUDE.md
# entry point, and adds both paths to the target project .gitignore.
#
# Usage:
#   bash install.sh                    # installs into current working directory
#   bash install.sh /path/to/project   # installs into the given project
#
# Idempotent: re-running preserves existing CLAUDE.md and does not duplicate
# .gitignore entries.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$PWD}"

if [ ! -d "$TARGET" ]; then
  echo "ERROR: target directory does not exist: $TARGET" >&2
  exit 1
fi

if [ ! -d "$SCRIPT_DIR/Efficiency" ]; then
  echo "ERROR: source Efficiency/ folder missing at $SCRIPT_DIR/Efficiency" >&2
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/CLAUDE-root-template.md" ]; then
  echo "ERROR: source CLAUDE-root-template.md missing at $SCRIPT_DIR" >&2
  exit 1
fi

echo "Installing Albert-Efficient-Init into: $TARGET"
echo

# 1. Copy Efficiency/ folder. -n means do not overwrite existing files.
mkdir -p "$TARGET/Efficiency"
copied_any=0
for src in "$SCRIPT_DIR/Efficiency/"*.md; do
  [ -f "$src" ] || continue
  base="$(basename "$src")"
  dest="$TARGET/Efficiency/$base"
  if [ -e "$dest" ]; then
    echo "  skip   Efficiency/$base (already present)"
  else
    cp "$src" "$dest"
    echo "  copy   Efficiency/$base"
    copied_any=1
  fi
done

# 2. Root CLAUDE.md. Only create if absent.
if [ -e "$TARGET/CLAUDE.md" ]; then
  echo "  skip   CLAUDE.md (already present)"
else
  cp "$SCRIPT_DIR/CLAUDE-root-template.md" "$TARGET/CLAUDE.md"
  echo "  copy   CLAUDE.md"
fi

# 3. Append to .gitignore (idempotent).
GITIGNORE="$TARGET/.gitignore"
touch "$GITIGNORE"

# Ensure the file ends with a newline before appending a section.
if [ -s "$GITIGNORE" ] && [ "$(tail -c1 "$GITIGNORE" | wc -l)" -eq 0 ]; then
  printf "\n" >> "$GITIGNORE"
fi

add_ignore() {
  local entry="$1"
  if grep -qxF "$entry" "$GITIGNORE"; then
    echo "  skip   .gitignore entry $entry (already present)"
  else
    echo "$entry" >> "$GITIGNORE"
    echo "  add    .gitignore entry $entry"
  fi
}

if ! grep -qF "# Albert-Efficient-Init" "$GITIGNORE"; then
  printf "\n# Albert-Efficient-Init (local-only rules)\n" >> "$GITIGNORE"
fi

add_ignore "/CLAUDE.md"
add_ignore "/Efficiency/"

echo
echo "Done."
echo
echo "Open the project in Claude Code. On the first turn Claude will read"
echo "CLAUDE.md and acknowledge that Albert-Efficient-Init rules are active."
