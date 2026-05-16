#!/usr/bin/env bash
#
# Albert-Efficient-Init uninstaller
#
# Removes the local rule files and strips the matching block from the target
# project .gitignore.
#
# Usage:
#   bash uninstall.sh                    # uninstalls from current working directory
#   bash uninstall.sh /path/to/project   # uninstalls from the given project
#
# Idempotent: re-running is safe even if some pieces are already absent.

set -euo pipefail

TARGET="${1:-$PWD}"

if [ ! -d "$TARGET" ]; then
  echo "ERROR: target directory does not exist: $TARGET" >&2
  exit 1
fi

echo "Uninstalling Albert-Efficient-Init from: $TARGET"
echo

# 1. Remove CLAUDE.md.
if [ -f "$TARGET/CLAUDE.md" ]; then
  rm -f "$TARGET/CLAUDE.md"
  echo "  remove CLAUDE.md"
else
  echo "  skip   CLAUDE.md (not present)"
fi

# 2. Remove Efficiency/.
if [ -d "$TARGET/Efficiency" ]; then
  rm -rf "$TARGET/Efficiency"
  echo "  remove Efficiency/"
else
  echo "  skip   Efficiency/ (not present)"
fi

# 3. Strip the .gitignore block.
GITIGNORE="$TARGET/.gitignore"
if [ -f "$GITIGNORE" ]; then
  # Remove the header comment, the two entries, and any leading blank line
  # that the installer inserted before the block.
  tmp="$(mktemp)"
  awk '
    BEGIN { skip_blank = 0 }
    /^# Albert-Efficient-Init/ { next }
    /^\/CLAUDE\.md$/ { next }
    /^\/Efficiency\/$/ { next }
    { print }
  ' "$GITIGNORE" > "$tmp"

  # Collapse trailing blank lines.
  awk 'NF { blanks=0; print; next } { blanks++; if (blanks==1) buf=$0; next } END { }' "$tmp" > "$GITIGNORE"
  rm -f "$tmp"
  echo "  clean  .gitignore"
else
  echo "  skip   .gitignore (not present)"
fi

echo
echo "Done."
