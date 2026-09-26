#!/usr/bin/env bash
# Prueba los bloques ```! de cada skill del plugin.
#
# Dos comprobaciones por bloque:
#   1. Sale 0 en los cuatro estados de repo. Un bloque que sale != 0 aborta la
#      invocacion entera de la skill.
#   2. No usa construcciones que el chequeo de permisos de Claude Code rechaza
#      aunque bash las acepte: grupos { ...; } y pipes dentro de un if de una
#      linea. Ver docs/comandos.md.
set -u
raiz="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fallos=0

git config --global user.email ci@example.com >/dev/null 2>&1 || true
git config --global user.name ci >/dev/null 2>&1 || true

mkdir -p "$tmp/normal" "$tmp/sinbase" "$tmp/nogit" "$tmp/vacio"
(cd "$tmp/normal" && git init -q -b main && git commit -q --allow-empty -m x && git switch -q -c trabajo)
(cd "$tmp/sinbase" && git init -q -b dev && git commit -q --allow-empty -m x)
(cd "$tmp/vacio" && git init -q)

for skill in "$raiz"/plugin/skills/*/SKILL.md; do
  nombre="$(basename "$(dirname "$skill")")"
  bloque="$tmp/$nombre.sh"
  awk '/^```!$/{f=1;next} f&&/^```$/{exit} f' "$skill" > "$bloque"
  [ -s "$bloque" ] || continue

  if grep -nE '(^|[;&|[:space:]])\{[[:space:]]|;[[:space:]]*\}' "$bloque"; then
    echo "FAIL  $nombre: grupo { ...; } en el bloque ! (Claude Code lo rechaza)"
    fallos=$((fallos + 1))
  fi
  if sed 's/||//g' "$bloque" | grep -nE '^[[:space:]]*if .*then .*\|.*fi'; then
    echo "FAIL  $nombre: pipe dentro de un if de una linea (Claude Code lo rechaza)"
    fallos=$((fallos + 1))
  fi

  for estado in normal sinbase nogit vacio; do
    if (cd "$tmp/$estado" && bash "$bloque" >/dev/null 2>&1); then
      echo "PASS  $nombre en $estado"
    else
      echo "FAIL  $nombre en $estado: el bloque ! sale != 0"
      fallos=$((fallos + 1))
    fi
  done
done

[ "$fallos" -eq 0 ] && echo "TODO OK" || echo "$fallos FALLOS"
exit $((fallos > 0))
