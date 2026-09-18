#!/usr/bin/env bash
#
# Albert-Efficient-Init bootstrap
#
# Clona (o actualiza) el repo en ~/.albert-efficient-init y corre el instalador.
# Pensado para el one-liner:
#
#   curl -fsSL https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/bootstrap.sh | bash
#
# Para pasarle flags al instalador a traves del pipe, usa `bash -s --`:
#
#   curl -fsSL .../bootstrap.sh | bash -s -- --skills
#
# Variables de entorno:
#   AEI_REPO  url del repo      (default: el de Kevin-ToJoin)
#   AEI_REF   rama o tag        (default: main)
#   AEI_DEST  donde clonar      (default: ~/.albert-efficient-init)

set -euo pipefail

REPO="${AEI_REPO:-https://github.com/Kevin-ToJoin/Albert-Efficient-Init}"
REF="${AEI_REF:-main}"
DEST="${AEI_DEST:-$HOME/.albert-efficient-init}"

command -v git >/dev/null 2>&1 || { echo "ERROR: git no esta instalado." >&2; exit 1; }

if [ -d "$DEST/.git" ]; then
  echo "Actualizando $DEST ($REF)"
  git -C "$DEST" fetch --depth 1 origin "$REF"
  git -C "$DEST" checkout -q --detach FETCH_HEAD
else
  echo "Clonando $REPO ($REF) -> $DEST"
  git clone --depth 1 --branch "$REF" "$REPO" "$DEST"
fi

echo
exec bash "$DEST/install.sh" "$@"
