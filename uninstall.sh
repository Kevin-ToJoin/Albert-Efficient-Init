#!/usr/bin/env bash
#
# Albert-Efficient-Init uninstaller
#
# Usage:
#   bash uninstall.sh                        # skills (user) + rules (cwd)
#   bash uninstall.sh --skills               # solo los slash commands
#   bash uninstall.sh --rules /path/to/proj  # solo CLAUDE.md + Efficiency/
#   bash uninstall.sh --scope project        # skills de <target>/.claude/skills
#   bash uninstall.sh --detach               # quita el marketplace del settings.json
#
# Options:
#   --skills / --rules   limitar a una de las dos partes
#   --scope user|project de donde quitar las skills (default: user)
#   --detach             quitar marketplace + plugin de <target>/.claude/settings.json
#   -h, --help           este mensaje

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_SKILLS="$SCRIPT_DIR/plugins/albert/skills"

MARKETPLACE_NAME="albert-efficient"
PLUGIN_NAME="albert"

TARGET=""
DO_SKILLS=1
DO_RULES=1
SCOPE="user"
DETACH=0

usage() { sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --skills) DO_SKILLS=1; DO_RULES=0 ;;
    --rules)  DO_RULES=1;  DO_SKILLS=0 ;;
    --scope)
      shift
      [ $# -gt 0 ] || { echo "ERROR: --scope necesita user|project" >&2; exit 2; }
      case "$1" in
        user|project) SCOPE="$1" ;;
        *) echo "ERROR: --scope invalido: $1" >&2; exit 2 ;;
      esac
      ;;
    --detach) DETACH=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "ERROR: opcion desconocida: $1 (usa --help)" >&2; exit 2 ;;
    *)
      [ -z "$TARGET" ] || { echo "ERROR: target duplicado: $1" >&2; exit 2; }
      TARGET="$1"
      ;;
  esac
  shift
done

TARGET="${TARGET:-$PWD}"
[ -d "$TARGET" ] || { echo "ERROR: el destino no existe: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

echo "Albert-Efficient-Init uninstall"
echo "  destino: $TARGET"
echo

remove_skills() {
  local dest_root
  if [ "$SCOPE" = "user" ]; then
    dest_root="$HOME/.claude/skills"
  else
    dest_root="$TARGET/.claude/skills"
  fi
  echo "Slash commands <- $dest_root"

  if [ ! -d "$SRC_SKILLS" ]; then
    echo "  ERROR: no encuentro $SRC_SKILLS, no se que quitar" >&2
    return 1
  fi

  # Solo borra directorios que este repo instala, nunca otras skills del usuario.
  for d in "$SRC_SKILLS"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    local name; name="$(basename "$d")"
    if [ -d "$dest_root/$name" ]; then
      rm -rf "$dest_root/$name"
      echo "  rm     $name/"
    else
      echo "  skip   $name/ (no estaba)"
    fi
  done
  rmdir "$dest_root" 2>/dev/null || true
  echo
}

remove_rules() {
  echo "Reglas local-only <- $TARGET"

  if [ -e "$TARGET/CLAUDE.md" ]; then
    rm -f "$TARGET/CLAUDE.md"; echo "  rm     CLAUDE.md"
  else
    echo "  skip   CLAUDE.md (no estaba)"
  fi

  if [ -d "$TARGET/Efficiency" ]; then
    rm -rf "$TARGET/Efficiency"; echo "  rm     Efficiency/"
  else
    echo "  skip   Efficiency/ (no estaba)"
  fi

  local gitignore="$TARGET/.gitignore"
  if [ -f "$gitignore" ]; then
    local tmp; tmp="$(mktemp)"
    # Quita el bloque que agrego el instalador y nada mas.
    grep -vxF -e "# Albert-Efficient-Init (local-only rules)" \
              -e "/CLAUDE.md" \
              -e "/Efficiency/" "$gitignore" > "$tmp" || true
    # Colapsa las lineas en blanco repetidas que deja el bloque removido y
    # quita las del final del archivo.
    awk 'NF==0 { pending=1; next }
         { if (pending && NR>1) print ""; pending=0; print }' "$tmp" > "$gitignore"
    rm -f "$tmp"
    echo "  clean  .gitignore"
  fi
  echo
}

detach_marketplace() {
  local settings="$TARGET/.claude/settings.json"
  echo "Marketplace <- $settings"
  if [ ! -f "$settings" ]; then
    echo "  skip   no existe"; echo; return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "  ERROR: --detach necesita python3. Quita a mano '$MARKETPLACE_NAME'" >&2
    echo "         de extraKnownMarketplaces y '$PLUGIN_NAME@$MARKETPLACE_NAME'" >&2
    echo "         de enabledPlugins en $settings" >&2
    return 1
  fi

  MP_NAME="$MARKETPLACE_NAME" PL_NAME="$PLUGIN_NAME" SETTINGS="$settings" python3 <<'PY'
import json, os, sys

path = os.environ["SETTINGS"]
mp, pl = os.environ["MP_NAME"], os.environ["PL_NAME"]

with open(path) as fh:
    text = fh.read().strip()
if not text:
    print("  skip   settings.json vacio"); sys.exit(0)
try:
    data = json.loads(text)
except json.JSONDecodeError as exc:
    sys.exit(f"  ERROR: {path} no es JSON valido ({exc}); no lo toco.")
if not isinstance(data, dict):
    sys.exit(f"  ERROR: {path} no es un objeto JSON; no lo toco.")

changed = []
markets = data.get("extraKnownMarketplaces")
if isinstance(markets, dict) and mp in markets:
    del markets[mp]
    changed.append(f"extraKnownMarketplaces.{mp}")
    if not markets:
        del data["extraKnownMarketplaces"]

plugins = data.get("enabledPlugins")
key = f"{pl}@{mp}"
if isinstance(plugins, dict) and key in plugins:
    del plugins[key]
    changed.append(f"enabledPlugins.{key}")
    if not plugins:
        del data["enabledPlugins"]

if not changed:
    print("  skip   nada que quitar"); sys.exit(0)

with open(path, "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
print("  rm     " + ", ".join(changed))
PY
  echo
}

if [ "$DO_SKILLS" -eq 1 ]; then remove_skills; fi
if [ "$DO_RULES" -eq 1 ]; then remove_rules; fi
if [ "$DETACH" -eq 1 ]; then detach_marketplace; fi

echo "Done."
