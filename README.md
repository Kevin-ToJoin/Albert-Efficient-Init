# Albert-Efficient-Init

Slash commands y reglas para Claude Code, empaquetados para engancharse a
cualquier repo sin fricción.

Dos piezas independientes. Puedes usar una, la otra, o ambas:

| Pieza | Qué es | Dónde vive | Alcance |
|---|---|---|---|
| **Comandos** | Slash commands como `/finalizar` | `~/.claude/skills/` | Todos tus repos |
| **Reglas** | `CLAUDE.md` + `Efficiency/`, gitignoreados | El proyecto destino | Ese repo, solo para ti |

> **Nota de terminología.** A esto se le suele llamar "webhook", pero en Claude
> Code no lo es. Un webhook es un callback HTTP. Lo que aquí se instala son
> **slash commands**, implementados como *skills*: archivos Markdown que Claude
> Code carga y tú invocas escribiendo `/nombre`.

## Instalación rápida

Una línea, sin clonar nada a mano:

```bash
curl -fsSL https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/bootstrap.sh | bash -s -- --skills
```

Eso clona el repo en `~/.albert-efficient-init` y copia los comandos a
`~/.claude/skills/`. Desde ese momento `/finalizar` funciona en **cualquier
repo** que abras con Claude Code, sin instalar nada por proyecto.

Para actualizar después, corre exactamente la misma línea.

### Si prefieres clonar tú

```bash
git clone https://github.com/Kevin-ToJoin/Albert-Efficient-Init ~/.albert-efficient-init
bash ~/.albert-efficient-init/install.sh --skills
```

### Windows

```powershell
git clone https://github.com/Kevin-ToJoin/Albert-Efficient-Init $env:USERPROFILE\.albert-efficient-init
powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\.albert-efficient-init\install.ps1 -SkillsOnly
```

## Los comandos

### `/finalizar`

Cierre de sesión de trabajo. Hace tres cosas y te molesta lo mínimo posible:

1. **Registra la deuda técnica** en `deuda-tecnica.md` del repo: lo que quedó a
   medias, los atajos que se tomaron, los `TODO`/`FIXME` del código que tocaste,
   los tests que faltan. Append, nunca sobrescribe.
2. **Commitea y mergea** la rama actual a la rama base (`main`, si no `master`,
   si no la que apunte `origin/HEAD`) y hace push si hay remoto.
3. **Reporta solo lo que tú tienes que hacer a mano.** Si no hay nada, responde
   `OK` y ya. Sin resúmenes, sin "he mergeado exitosamente", sin siguientes
   pasos.

```
/finalizar
/finalizar "refactor del cliente de pagos"     # mensaje de commit explícito
```

Lo que **sí** te reporta: conflictos de merge, push rechazado o rama protegida,
credenciales que faltan, decisiones de producto que no le tocan tomar, cosas
fuera del repo, comandos que fallaron.

Lo que **no** te reporta, porque queda escrito en `deuda-tecnica.md`: refactors
pendientes, tests faltantes, `TODO`s del código.

Nunca hace `--force` push, y ante un conflicto aborta el merge, te devuelve a tu
rama y te lo reporta en lugar de resolverlo por su cuenta.

## Formas de engancharlo a un repo

Elige una. La primera es la que querrás el 90% de las veces.

### 1. Personal, todos los repos (recomendado)

```bash
bash install.sh --skills
```

Copia a `~/.claude/skills/`. `/finalizar` disponible en todo. Nada que
commitear, nada que tus colaboradores vean. Es el camino sin fricción.

### 2. Solo este repo

```bash
bash install.sh --skills --scope project /ruta/al/proyecto
```

Copia a `<proyecto>/.claude/skills/`. Si commiteas ese directorio, el comando le
llega a todo el equipo.

### 3. Como plugin desde el marketplace

Este repo **es** un marketplace de plugins. Desde Claude Code:

```
/plugin marketplace add Kevin-ToJoin/Albert-Efficient-Init
/plugin install albert@albert-efficient
```

Aquí el comando queda con namespace: `/albert:finalizar`. A cambio obtienes
versionado y actualizaciones automáticas. Útil para compartir con un equipo.

### 4. Declarado en el repo (sesiones cloud y equipo)

```bash
bash install.sh --attach /ruta/al/proyecto
```

Escribe `<proyecto>/.claude/settings.json` con el marketplace registrado y el
plugin habilitado, para que las sesiones en claude.ai/code y los colaboradores
lo levanten solos:

```json
{
  "extraKnownMarketplaces": {
    "albert-efficient": {
      "source": { "source": "github", "repo": "Kevin-ToJoin/Albert-Efficient-Init" }
    }
  },
  "enabledPlugins": { "albert@albert-efficient": true }
}
```

Ese archivo está pensado para commitearse. Si no quieres que viaje con el repo,
usa `settings.local.json` o quédate con la opción 1.

## Las reglas local-only

La parte original de este repo: `CLAUDE.md` + `Efficiency/` con perfiles de
reglas token-efficient, instalados **gitignoreados** para que reflejen tu
preferencia personal sin imponérsela a nadie.

```bash
bash install.sh --rules            # en el directorio actual
bash install.sh --rules /ruta/al/proyecto
```

Instala:

```
tu-proyecto/
  CLAUDE.md              # gitignoreado, punto de entrada
  Efficiency/            # gitignoreado, perfiles
    rules-coding.md      # desarrollo, code review, debugging
    rules-analysis.md    # análisis de datos, research, reporting
    README.md
  .gitignore             # trackeado, se le añaden dos líneas
```

Las reglas base siempre están activas; los perfiles se cargan solo cuando la
tarea lo pide.

## Referencia del instalador

```
bash install.sh [opciones] [destino]

  --skills            solo los slash commands
  --rules             solo CLAUDE.md + Efficiency/
                      (sin ninguno de los dos: ambos)
  --scope user        skills a ~/.claude/skills  (default, todos los repos)
  --scope project     skills a <destino>/.claude/skills
  --attach            registrar el marketplace en <destino>/.claude/settings.json
  --force             sobrescribir archivos existentes
  --list              listar los comandos disponibles
  -h, --help
```

Idempotente: re-ejecutarlo no pisa nada salvo con `--force`, y no duplica
entradas en `.gitignore`. Equivalentes en PowerShell: `-SkillsOnly`,
`-RulesOnly`, `-Scope`, `-Attach`, `-Force`, `-List`.

## Desinstalar

```bash
bash uninstall.sh                   # comandos (user) + reglas (cwd)
bash uninstall.sh --skills          # solo los comandos
bash uninstall.sh --rules /ruta     # solo las reglas de ese proyecto
bash uninstall.sh --detach /ruta    # además, quitar el marketplace del settings.json
```

Solo borra las skills que este repo instala. Otras skills tuyas en
`~/.claude/skills/` no se tocan.

## Agregar tus propios comandos

Un comando nuevo es un directorio con un `SKILL.md`. Ver
[docs/comandos.md](docs/comandos.md) para el formato, los argumentos, la
inyección de contexto con `` !`cmd` `` y el checklist antes de commitear.

## Estructura del repo

```
.claude-plugin/marketplace.json     # catálogo: hace que el repo sea un marketplace
plugins/albert/
  .claude-plugin/plugin.json        # manifiesto del plugin
  skills/
    finalizar/SKILL.md              # el comando /finalizar
Efficiency/                         # perfiles de reglas
CLAUDE-root-template.md             # plantilla del CLAUDE.md que se instala
bootstrap.sh                        # clona + instala (el one-liner)
install.sh / install.ps1
uninstall.sh / uninstall.ps1
docs/comandos.md
```

`plugins/albert/skills/` es la **única** fuente de cada comando. El instalador
copia desde ahí y el marketplace apunta ahí. No hay copias que se
desincronicen.

## Atribución

Las reglas de eficiencia derivan de ideas de
[drona23/claude-token-efficient](https://github.com/drona23/claude-token-efficient)
(MIT). Ver [ATTRIBUTION.md](ATTRIBUTION.md).

## Licencia

MIT. Ver [LICENSE](LICENSE).
