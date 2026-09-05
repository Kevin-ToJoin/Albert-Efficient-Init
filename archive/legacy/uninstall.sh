#!/usr/bin/env bash
#
# Albert-Efficient-Init uninstaller (DEPRECADO)
#
# Este script existe solo para limpiar proyectos donde se ejecuto el instalador
# antiguo, que copiaba CLAUDE.md y Efficiency/ dentro del repo destino. Ese
# modelo se sustituyo por plugins, que no tocan el repo destino.
#
# Se eliminara en la siguiente release. No hay nada nuevo que desinstalar con el.
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

  # Collapse trailing blank lines only. Interior blank lines are preserved:
  # blanks are buffered and emitted only when more content follows.
  awk '
    /^[[:space:]]*$/ { pending++; next }
    { while (pending > 0) { print ""; pending-- } print }
  ' "$tmp" > "$GITIGNORE"
  rm -f "$tmp"
  echo "  clean  .gitignore"
else
  echo "  skip   .gitignore (not present)"
fi

echo
echo "Done."
