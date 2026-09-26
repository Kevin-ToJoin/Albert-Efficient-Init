# Albert-Efficient-Init

Toolkit de Claude Code que se integra en **cualquier repositorio** y le llega a
todo el equipo. Trae cinco piezas:

| Pieza | Qué es | Dónde vive |
|---|---|---|
| **Skills** | Comandos como `/albert:finalizar` y los perfiles de reglas | `plugin/skills/` |
| **Subagentes** | Auditorías que corren en su propio contexto | `plugin/agents/` |
| **Hooks** | Guards deterministas que bloquean lo peligroso | `plugin/hooks/` |
| **MCP** | Conexiones a sistemas externos | `plugin/.mcp.json` |
| **Reglas base** | Lo que antes iba en el `CLAUDE.md`: llegan solas en cada sesión | `plugin/reglas-base.md` |

Se distribuye como **plugin de Claude Code**. Este repo es a la vez el
marketplace (`.claude-plugin/marketplace.json`) y el plugin (`plugin/`). Nada
se copia a mano y no hay instalador.

## Integrarlo en un repositorio

**Un comando**, desde la raíz del repo. En Mac o Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/instalar/instalar.js | node -
```

En Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/instalar/instalar.js | node -
```

Después abre el repo con `claude` y acepta la confianza de la carpeta. Ya está.

**No deja nada que commitear.** Agrega el toolkit a `.claude/settings.local.json`,
el archivo de configuración personal de Claude Code, y lo excluye de git en
`.git/info/exclude`, que es local. No toca el `.gitignore` ni ningún archivo
del repo, y si ya tenías ese archivo con permisos, los conserva. Cada persona
que lo quiera corre el comando en su máquina.

**Para que lo reciba todo el equipo sin correr nada**, agrega `--equipo` al
final (`... | node - --equipo`). Escribe `.claude/settings.json`, que se
commitea: quien clone el repo lo recibe al confiar en la carpeta.

Requisitos, qué ve cada uno y problemas frecuentes:
**[docs/instalar.md](docs/instalar.md)**.

Las claves que agrega, por si prefieres escribirlas a mano:

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

Las reglas base no se copian a tu `CLAUDE.md`: el plugin las inyecta en cada
sesión. Tu `CLAUDE.md` queda para lo propio del proyecto;
`/albert:iniciar` te crea uno con la estructura sugerida.

### Actualizaciones

`"autoUpdate": true` hace que Claude Code refresque el plugin en segundo plano
durante cada sesión interactiva (hasta 10 minutos después del primer mensaje),
y la siguiente sesión ya carga la versión nueva. El
plugin no declara `version` a propósito, así que cada commit a `main` de este
repo es una actualización: no hay que subir ningún número de versión.

Para forzarlo en el momento: `/plugin marketplace update albert-efficient-init`.

### Quitarlo

Borra las dos claves del archivo donde estén: `.claude/settings.local.json`
(personal) o `.claude/settings.json` (equipo, y commitea).

## Las skills

Todas llevan el prefijo del plugin: `/albert:<nombre>`.

### `/albert:iniciar`

Opcional. Revisa la integración: completa las claves del toolkit si les falta
algo (por ejemplo, el `autoUpdate`, si se instaló desde el panel de `/plugin`)
y crea un `CLAUDE.md` con la estructura sugerida para lo propio del proyecto.
Si tu `CLAUDE.md` tiene reglas base copiadas por una versión anterior, te
ofrece quitarlas, porque ahora llegan solas.

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
- **`reglas-base.js`**: inyecta las reglas base en cada sesión y en cada
  subagente. Así llegan sin copiarse a tu `CLAUDE.md`, y se actualizan solas.

Los tres fallan abierto: si algo no cuadra, dejan pasar sin romper la sesión. Están en
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
  reglas-base.md                  lo que el hook inyecta en cada sesión
  skills/                         iniciar, finalizar, lanzar-dominio, perfil-*
  agents/                         auditor-deuda, auditor-seguridad
  hooks/                          hooks.json, guards, reglas-base.js y pruebas
  .mcp.json
instalar/instalar.js              el comando de integración, con sus pruebas
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
