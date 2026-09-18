# Plugin `albert`

Comandos de workflow para Claude Code.

Este directorio es la fuente única de los comandos. Lo consumen tres caminos:

- `install.sh --skills` los copia a `~/.claude/skills/` → `/finalizar`
- `install.sh --skills --scope project` los copia a `.claude/skills/` → `/finalizar`
- `/plugin install albert@albert-efficient` los carga como plugin → `/albert:finalizar`

## Comandos

| Comando | Qué hace |
|---|---|
| `finalizar` | Cierra la sesión: deuda técnica a `deuda-tecnica.md`, commit, merge a la rama base, push. Reporta solo lo que requiere acción manual. |

## Agregar uno

Ver [../../docs/comandos.md](../../docs/comandos.md).
