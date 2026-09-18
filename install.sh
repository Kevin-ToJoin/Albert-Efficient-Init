#!/usr/bin/env bash
#
# Albert-Efficient-Init installer
#
# Installs two independent things into wherever you want them:
#
#   skills  ->  slash commands like /finalizar, usable in any repo
#   rules   ->  the gitignored CLAUDE.md + Efficiency/ profiles, per project
#
# Usage:
#   bash install.sh                        # skills (user scope) + rules (cwd)
#   bash install.sh --skills               # only the slash commands
#   bash install.sh --rules /path/to/proj  # only the rule files
#   bash install.sh --scope project        # skills into ./.claude/skills instead
#   bash install.sh --attach               # register the marketplace in the repo
#
# Options:
#   --skills            install only the slash commands
#   --rules             install only CLAUDE.md + Efficiency/
#   --scope user        skills into ~/.claude/skills (default; every repo)
#   --scope project     skills into <target>/.claude/skills (this repo only)
#   --attach            write <target>/.claude/settings.json so the plugin
#                       marketplace is registered for this repo and for cloud
#                       sessions
#   --force             overwrite files that already exist
#   --list              print what is available and exit
#   -h, --help          this message
#
# Idempotent: re-running preserves existing files unless --force is passed, and
# never duplicates .gitignore entries.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugins/albert"
SRC_SKILLS="$PLUGIN_DIR/skills"

MARKETPLACE_NAME="albert-efficient"
PLUGIN_NAME="albert"
REPO_SLUG="Kevin-ToJoin/Albert-Efficient-Init"

TARGET=""
DO_SKILLS=1
DO_RULES=1
SCOPE="user"
ATTACH=0
FORCE=0

usage() { sed -n '2,36p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --skills) DO_SKILLS=1; DO_RULES=0 ;;
    --rules)  DO_RULES=1;  DO_SKILLS=0 ;;
    --scope)
      shift
      [ $# -gt 0 ] || { echo "ERROR: --scope necesita user|project" >&2; exit 2; }
      case "$1" in
        user|project) SCOPE="$1" ;;
        *) echo "ERROR: --scope invalido: $1 (usa user|project)" >&2; exit 2 ;;
      esac
      ;;
    --attach) ATTACH=1 ;;
    --force)  FORCE=1 ;;
    --list)
      echo "Skills disponibles en $SRC_SKILLS:"
      for d in "$SRC_SKILLS"/*/; do
        [ -f "$d/SKILL.md" ] || continue
        echo "  /$(basename "$d")"
      done
      exit 0
      ;;
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

if [ ! -d "$TARGET" ]; then
  echo "ERROR: el directorio destino no existe: $TARGET" >&2
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"

copy_file() {
  # copy_file <src> <dest> <label>
  local src="$1" dest="$2" label="$3"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    echo "  skip   $label (ya existe, usa --force para sobrescribir)"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  if [ "$FORCE" -eq 1 ]; then echo "  write  $label"; else echo "  copy   $label"; fi
}

# ---------------------------------------------------------------- skills ------

install_skills() {
  if [ ! -d "$SRC_SKILLS" ]; then
    echo "ERROR: no encuentro las skills en $SRC_SKILLS" >&2
    exit 1
  fi

  local dest_root
  if [ "$SCOPE" = "user" ]; then
    dest_root="$HOME/.claude/skills"
  else
    dest_root="$TARGET/.claude/skills"
  fi

  echo "Slash commands -> $dest_root  (scope: $SCOPE)"

  local found=0
  for d in "$SRC_SKILLS"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    found=1
    local name; name="$(basename "$d")"
    # Copy the whole skill directory so supporting files travel with SKILL.md.
    while IFS= read -r rel; do
      copy_file "$d$rel" "$dest_root/$name/$rel" "$name/$rel"
    done < <(cd "$d" && find . -type f -print | sed 's|^\./||')
  done

  if [ "$found" -eq 0 ]; then
    echo "  (ninguna skill encontrada)"
  fi
  echo
}

# ----------------------------------------------------------------- rules ------

install_rules() {
  if [ ! -d "$SCRIPT_DIR/Efficiency" ]; then
    echo "ERROR: falta $SCRIPT_DIR/Efficiency" >&2
    exit 1
  fi
  if [ ! -f "$SCRIPT_DIR/CLAUDE-root-template.md" ]; then
    echo "ERROR: falta $SCRIPT_DIR/CLAUDE-root-template.md" >&2
    exit 1
  fi

  echo "Reglas local-only -> $TARGET"

  mkdir -p "$TARGET/Efficiency"
  for src in "$SCRIPT_DIR/Efficiency/"*.md; do
    [ -f "$src" ] || continue
    copy_file "$src" "$TARGET/Efficiency/$(basename "$src")" "Efficiency/$(basename "$src")"
  done

  copy_file "$SCRIPT_DIR/CLAUDE-root-template.md" "$TARGET/CLAUDE.md" "CLAUDE.md"

  local gitignore="$TARGET/.gitignore"
  touch "$gitignore"
  # Guarantee a trailing newline before appending.
  if [ -s "$gitignore" ] && [ "$(tail -c1 "$gitignore" | wc -l)" -eq 0 ]; then
    printf "\n" >> "$gitignore"
  fi

  if ! grep -qF "# Albert-Efficient-Init" "$gitignore"; then
    printf "\n# Albert-Efficient-Init (local-only rules)\n" >> "$gitignore"
  fi

  local entry
  for entry in "/CLAUDE.md" "/Efficiency/"; do
    if grep -qxF "$entry" "$gitignore"; then
      echo "  skip   .gitignore $entry (ya presente)"
    else
      echo "$entry" >> "$gitignore"
      echo "  add    .gitignore $entry"
    fi
  done
  echo
}

# ---------------------------------------------------------------- attach ------

attach_marketplace() {
  local settings="$TARGET/.claude/settings.json"
  echo "Marketplace -> $settings"

  if ! command -v python3 >/dev/null 2>&1; then
    cat <<MSG
  ERROR: --attach necesita python3 para no romper el settings.json existente.
  Agrega esto a mano en $settings:

  {
    "extraKnownMarketplaces": {
      "$MARKETPLACE_NAME": {
        "source": { "source": "github", "repo": "$REPO_SLUG" }
      }
    },
    "enabledPlugins": { "$PLUGIN_NAME@$MARKETPLACE_NAME": true }
  }
MSG
    return 1
  fi

  mkdir -p "$TARGET/.claude"
  MP_NAME="$MARKETPLACE_NAME" PL_NAME="$PLUGIN_NAME" RP_SLUG="$REPO_SLUG" \
  SETTINGS="$settings" python3 <<'PY'
import json, os, sys

path = os.environ["SETTINGS"]
mp, pl, repo = os.environ["MP_NAME"], os.environ["PL_NAME"], os.environ["RP_SLUG"]

data = {}
if os.path.exists(path):
    with open(path) as fh:
        text = fh.read().strip()
    if text:
        try:
            data = json.loads(text)
        except json.JSONDecodeError as exc:
            sys.exit(f"  ERROR: {path} no es JSON valido ({exc}); no lo toco.")
    if not isinstance(data, dict):
        sys.exit(f"  ERROR: {path} no es un objeto JSON; no lo toco.")

markets = data.setdefault("extraKnownMarketplaces", {})
if not isinstance(markets, dict):
    sys.exit("  ERROR: extraKnownMarketplaces existe y no es un objeto; no lo toco.")
markets[mp] = {"source": {"source": "github", "repo": repo}}

plugins = data.setdefault("enabledPlugins", {})
if not isinstance(plugins, dict):
    sys.exit("  ERROR: enabledPlugins existe y no es un objeto; no lo toco.")
plugins[f"{pl}@{mp}"] = True

with open(path, "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")

print(f"  write  .claude/settings.json ({mp} + {pl}@{mp})")
PY

  cat <<MSG

  .claude/settings.json esta pensado para commitearse. Si prefieres que no
  viaje con el repo, usa settings.local.json o instala con --scope user.
MSG
  echo
}

# ------------------------------------------------------------------ main ------

echo "Albert-Efficient-Init"
echo "  origen:  $SCRIPT_DIR"
echo "  destino: $TARGET"
echo

if [ "$DO_SKILLS" -eq 1 ]; then install_skills; fi
if [ "$DO_RULES" -eq 1 ]; then install_rules; fi
if [ "$ATTACH" -eq 1 ]; then attach_marketplace; fi

echo "Done."
if [ "$DO_SKILLS" -eq 1 ]; then
  echo
  if [ "$SCOPE" = "user" ]; then
    echo "Abre Claude Code en cualquier repo y escribe /finalizar."
  else
    echo "Abre Claude Code en $TARGET y escribe /finalizar."
  fi
  echo "Si la sesion ya estaba abierta, corre /reload-plugins primero."
fi
