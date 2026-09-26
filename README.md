# Albert-Efficient-Init

Toolkit de Claude Code que se integra en **cualquier repositorio** y le llega a
todo el equipo. Trae cinco piezas:

| Pieza | Qué es | Dónde vive |
|---|---|---|
| **Skills** | Comandos como `/albert:finalizar` y los perfiles de reglas | `plugin/skills/` |
| **Subagentes** | Auditorías que corren en su propio contexto | `plugin/agents/` |
| **Hooks** | Guards deterministas que bloquean lo peligroso | `plugin/hooks/` |
| **MCP** | Conexiones a sistemas externos | `plugin/.mcp.json` |
| **CLAUDE.md** | Reglas base que `/albert:iniciar` escribe en el repo | `plugin/skills/iniciar/` |

Se distribuye como **plugin de Claude Code**. Este repo es a la vez el
marketplace (`.claude-plugin/marketplace.json`) y el plugin (`plugin/`). Nada
se copia a mano y no hay instalador.

## Integrarlo en un repositorio

Una vez por repo, desde la raíz del repo destino, en una sesión de Claude Code:

```text
/plugin marketplace add Kevin-ToJoin/Albert-Efficient-Init
/plugin install albert@albert-efficient-init
/albert:iniciar
```

Al instalar, elige **Install for all collaborators on this repository**
(alcance de proyecto). `/albert:iniciar` deja dos archivos listos para
commitear:

- **`CLAUDE.md`** con las reglas base. Si ya tenías uno, las agrega al final
  sin tocar lo tuyo.
- **`.claude/settings.json`** con el marketplace y el plugin habilitados. Si ya
  existía, lo mergea sin pisar tus `permissions` ni tus hooks:

```json
{
  "extraKnownMarketplaces": {
    "albert-efficient-init": {
      "source": { "source": "github", "repo": "Kevin-ToJoin/Albert-Efficient-Init" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "albert@albert-efficient-init": true
  }
}
```

Commitea los dos. A partir de ahí, **quien clone el repo lo recibe solo**: al
abrirlo en Claude Code y aceptar el diálogo de confianza de la carpeta, Claude
Code registra el marketplace y carga el plugin, sin instalar nada.

> Si en el repo destino `.claude/` o `CLAUDE.md` están en el `.gitignore`, el
> equipo no recibe nada. `/albert:iniciar` te avisa si es el caso.

### Actualizaciones

`"autoUpdate": true` hace que Claude Code refresque el plugin en segundo plano
al arrancar cada sesión, y la siguiente sesión ya carga la versión nueva. El
plugin no declara `version` a propósito, así que cada commit a `main` de este
repo es una actualización: no hay que subir ningún número de versión.

Para forzarlo en el momento: `/plugin marketplace update albert-efficient-init`.

### Quitarlo

`/plugin uninstall albert@albert-efficient-init`. Te pregunta si quieres
desactivarlo solo para ti o quitarlo para todo el equipo. En el segundo caso,
borra también el bloque de `.claude/settings.json` y, si quieres, las reglas
base del `CLAUDE.md`.

## Las skills

Todas llevan el prefijo del plugin: `/albert:<nombre>`.

### `/albert:iniciar`

Integra el toolkit en el repo actual: escribe el `CLAUDE.md` y el
`.claude/settings.json` de arriba. Es idempotente, así que correrlo dos veces no
duplica nada. Si las reglas base de tu `CLAUDE.md` difieren de la plantilla
actual, no las pisa: te avisa y decides tú.

### `/albert:finalizar`

Cierre de sesión de trabajo. Hace tres cosas y te molesta lo mínimo posible:

1. **Registra la deuda técnica** en el `deuda-tecnica.md` del repo: lo que quedó
   a medias, los atajos, los `TODO`/`FIXME` del código que tocaste, los tests que
   faltan. Solo agrega, nunca sobrescribe.
2. **Commitea y mergea** la rama actual a la base (`main`, si no `master`, si no
   la que apunte `origin/HEAD`) y hace push si hay remoto.
3. **Reporta solo lo que tú tienes que hacer a mano.** Si no hay nada, responde
   `OK` y ya.

```text
/albert:finalizar
/albert:finalizar "refactor del cliente de pagos"     # mensaje de commit explícito
```

Nunca hace `push --force`. Ante un conflicto, aborta el merge, te devuelve a tu
rama y te lo dice en vez de resolverlo por su cuenta.

### `/albert:lanzar-dominio`

Checklist de puesta en marcha de un dominio. Propone el reparto en subdominios
(sitio, app, correo transaccional y campañas separados, para que una campaña
marcada como spam no se lleve por delante tus correos de recuperar contraseña),
genera `robots.txt` y sitemap si hacen falta, y marca como pendiente tuyo lo que
no puede hacer: DNS, registrador y Search Console.

### Los perfiles

`albert:perfil-codigo`, `albert:perfil-analisis` y `albert:perfil-seguridad`
son reglas que Claude carga **solo cuando la tarea lo pide**, para no gastar
contexto en reglas que no aplican. No hace falta invocarlos: Claude lee su
descripción y decide. También puedes pedirlos: *"aplica el perfil de código y
revisa esta función"*.

## Los subagentes

Corren en **su propia ventana de contexto** y te devuelven solo el resultado,
para que el trabajo pesado de exploración no te llene la conversación
principal.

### `@agent-albert:auditor-deuda`

Barre el repo buscando `TODO`/`FIXME`/`HACK`, tests saltados y trabajo a
medias, lo cruza contra `deuda-tecnica.md` y te reporta **solo lo que no está
registrado**. No escribe en ningún archivo: quien registra es
`/albert:finalizar`.

### `@agent-albert:auditor-seguridad`

Audita una app contra nueve puntos básicos: secretos fuera del repo, tablas no
públicas, row-level security, auth en rutas protegidas, tokens validados en el
servidor, rate limiting, errores que no filtran stack traces, endpoints de debug
bloqueados y logging. Separa lo que falta de lo que **no se puede verificar
desde el código**.

## Los hooks

Se activan solos con el plugin: no hay que tocar ningún `settings.json`. Son lo
único del toolkit que **se cumple siempre**; una regla del `CLAUDE.md` se
cumple casi siempre.

- **`guard-git-destructivo.js`**: bloquea `git push --force`, `reset --hard`,
  `clean -f` y `branch -D`, y deja pasar las variantes seguras
  (`--force-with-lease`, `clean -n`, `branch -d`).
- **`guard-secretos.js`**: impide stagear o commitear `.env`, `*.pem`, `id_rsa`
  o `credentials.json`, y bloquea comandos con un token escrito dentro. Mira
  también lo que ya está en el index. Deja pasar `.env.example`.

Los dos fallan abierto: si no entienden su entrada, dejan pasar. Están en
**Node** sin dependencias, porque un hook lo ejecuta el sistema operativo y el
toolkit tiene que correr igual en Windows, macOS y Linux. **Lo único que
necesita la máquina es Node.**

## Los MCP

Los servidores declarados en `plugin/.mcp.json` le llegan a todo repo que
integre el toolkit. Hoy no hay ninguno: se agrega uno cuando un sistema externo
lo justifica, no por si acaso. La plantilla con los cuatro transportes y la
trampa de las variables con `TOKEN` o `KEY` en el nombre están en
[docs/mcp.md](docs/mcp.md).

## Estructura del repo

```text
.claude-plugin/marketplace.json   el catálogo: un plugin, "albert", en ./plugin
plugin/                           lo que le llega a los repos que lo integran
  .claude-plugin/plugin.json
  skills/                         iniciar, finalizar, lanzar-dominio, perfil-*
  agents/                         auditor-deuda, auditor-seguridad
  hooks/                          hooks.json + guards en Node + sus pruebas
  .mcp.json
docs/                             cómo escribir cada pieza y qué va en cada una
CLAUDE.md                         cómo trabajar en ESTE repo
deuda-tecnica.md                  pendientes, mantenido por /albert:finalizar
```

## Agregar lo tuyo

Cada tipo de pieza tiene su guía con **qué merece guardarse ahí y qué no**:
[skills](docs/skills.md), [comandos](docs/comandos.md),
[subagentes](docs/agentes.md), [hooks](docs/hooks.md), [MCP](docs/mcp.md) y
[CLAUDE.md](docs/claude-md.md). Todo lo nuevo va dentro de `plugin/`. Al hacer
push a `main`, les llega a todos los repos que lo integran.

Para probar un cambio antes de publicarlo, arranca Claude Code con el plugin
local:

```bash
claude --plugin-dir ./plugin
```

## Atribución

Las reglas de eficiencia derivan de ideas de
[drona23/claude-token-efficient](https://github.com/drona23/claude-token-efficient)
(MIT). Ver [ATTRIBUTION.md](ATTRIBUTION.md).

## Licencia

MIT. Ver [LICENSE](LICENSE).
