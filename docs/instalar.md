# Guia: integrar Albert-Efficient-Init en un repo

Para quien nunca lo ha hecho. Al terminar, tu repo tiene los comandos
`/albert:...`, los subagentes, los hooks de seguridad y las reglas base.

**Es un solo comando, y no deja nada que commitear.**

---

## Antes de empezar

En la maquina de cada persona que use el repo:

| Necesitas | Para que | Comprobarlo |
|---|---|---|
| [Claude Code](https://code.claude.com/docs/en/setup) | Todo | `claude --version` |
| git | Claude Code descarga el toolkit con git | `git --version` |
| [Node](https://nodejs.org) | El comando de integracion, los hooks de seguridad y las reglas base | `node --version` |

No hace falta cuenta ni credenciales de GitHub: el toolkit es publico.

> Si ya integraste con `--equipo` y a un companero le falta Node, los comandos
> y los subagentes le funcionan igual, pero sin guards ni reglas base.

---

## Integrarlo

### 1. Corre el comando

En una terminal, desde la carpeta del repo (sirve cualquier subcarpeta):

**Mac o Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/instalar/instalar.js | node -
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/instalar/instalar.js | node -
```

Tiene que terminar con:

```text
Listo: .claude/settings.local.json
Excluido de git en .git/info/exclude: no hay nada que commitear.
Abre el repo con `claude` y acepta la confianza de la carpeta.
```

Que hizo:

- Agrego el toolkit a `.claude/settings.local.json`, el archivo de
  configuracion personal de Claude Code. Si ya existia, con permisos que
  fuiste aprobando, los conserva.
- Lo excluyo de git en `.git/info/exclude`. Ese archivo es local, no se
  commitea, asi que **no se toca el `.gitignore` ni nada del repo**:
  `git status` queda igual que antes.

Correrlo dos veces no duplica nada.

### 2. Abre el repo en Claude Code

```bash
claude
```

Cuando pregunte si confias en la carpeta, di **que si**. Ya esta.

### Para todo el equipo de una vez

Lo de arriba es personal: cada persona que lo quiera corre el comando. Si
prefieres que lo reciba **todo el equipo sin correr nada**, agrega `--equipo`:

```bash
curl -fsSL https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/instalar/instalar.js | node - --equipo
```

Escribe `.claude/settings.json` en lugar del archivo personal. Ese si se
commitea y se sube: quien clone el repo recibe el toolkit al abrirlo con
`claude` y confiar en la carpeta.

---

## Comprueba que funciona

1. Escribe `/albert:` y tienen que aparecer `iniciar`, `finalizar`,
   `lanzar-dominio` y los tres `perfil-...`.
2. Pidele a Claude: *"ejecuta `git branch -D rama-que-no-existe`"*. Tiene que
   contestar que un hook lo bloqueo.

## Opcional: el CLAUDE.md de tu proyecto

Las reglas base ya llegan solas. Tu `CLAUDE.md` es para lo que solo aplica a
**tu** proyecto: stack, comandos, convenciones, trampas. Para empezar con la
estructura sugerida:

```text
/albert:iniciar
```

Crea el `CLAUDE.md` si no existe y revisa que las claves del toolkit esten
completas. No commitea: revisa y sube tu.

---

## Si te sumas a un repo que ya lo tiene

- **Si se integro con `--equipo`**: clona el repo, abrelo con `claude` y acepta
  la confianza de la carpeta. Nada mas.
- **Si no**: corre tu el comando del paso 1.

---

## Que tienes ahora

| Que | Como se usa |
|---|---|
| Reglas base | Siempre activas. Estan en [plugin/reglas-base.md](../plugin/reglas-base.md) |
| Perfiles de codigo, analisis y seguridad | Se cargan solos cuando la tarea lo pide |
| Guards | Siempre activos: bloquean `push --force`, `reset --hard` y commitear `.env` o llaves |
| `/albert:finalizar` | Al terminar de trabajar: registra pendientes, commitea, mergea y hace push |
| `/albert:lanzar-dominio` | Al comprar un dominio o antes de publicar un sitio |
| `/albert:iniciar` | Opcional: crea tu `CLAUDE.md` y revisa la integracion |
| `@agent-albert:auditor-deuda` | *"@agent-albert:auditor-deuda revisa que deuda falta registrar"* |
| `@agent-albert:auditor-seguridad` | Antes de publicar: audita la app contra nueve puntos basicos |

## Actualizaciones

Automaticas. En una sesion interactiva, hasta 10 minutos despues de tu primer
mensaje, Claude Code busca cambios en segundo plano, y **la siguiente** sesion
ya usa la version nueva. Si ves
`Plugin updated ... Run /reload-plugins to apply`, escribe `/reload-plugins`
para no esperar.

Para forzarla: `/plugin marketplace update albert-efficient-init`.

## Quitarlo

Borra las claves `albert-efficient-init` y `albert@albert-efficient-init` del
archivo donde esten: `.claude/settings.local.json` (personal) o
`.claude/settings.json` (equipo, y commitea el cambio).

---

## Problemas frecuentes

| Ves esto | Que pasa | Que hacer |
|---|---|---|
| `/albert:` no muestra nada | No aceptaste la confianza de la carpeta, o el plugin no cargo | Reabre `claude` y acepta; si sigue, `/plugin`, pestana **Errors** |
| A un companero no le aparece | El modo personal es por persona | Que corra el comando, o integralo con `--equipo` |
| Con `--equipo`, el equipo no recibe nada | `.claude/` esta en el `.gitignore`, o no se subio | Quitalo del `.gitignore` y sube `.claude/settings.json` |
| Aviso de hook con `node` al abrir la sesion o en cada comando | Node no esta instalado | Instala Node |
| En Windows, `irm` falla al descargar | PowerShell antiguo sin TLS 1.2, o red bloqueada | Antepon `[Net.ServicePointManager]::SecurityProtocol='Tls12';` al comando, o agrega las claves a mano (estan en el [README](../README.md#integrarlo-en-un-repositorio)) |
| `No se toco .claude/settings.local.json: no es JSON valido` | El archivo existente esta roto | Corrigelo y vuelve a correr el comando. El instalador nunca pisa un archivo que no entiende |
| `node` no se reconoce | Node no esta instalado | Instala Node: el toolkit lo necesita de todos modos |
| No llegan las actualizaciones | El auto-update corre en sesiones interactivas, hasta 10 minutos despues del primer mensaje, y carga en la sesion siguiente | Espera a la proxima sesion, o `/plugin marketplace update albert-efficient-init` |
| Con `claude -p` (CI, scripts) no aparece el plugin | En modo no interactivo el plugin carga en segundo plano y puede faltar en el primer turno | Define `CLAUDE_CODE_SYNC_PLUGIN_INSTALL=1` para que espere a cargarlo |
