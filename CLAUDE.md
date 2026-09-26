<!--
QUE VA EN ESTE ARCHIVO
======================

Claude Code lo lee entero al arrancar cada sesion y lo pega a tu prompt. Es el
guion de onboarding del repo: lo que le explicarias a alguien nuevo para que no
tenga que adivinar ni re-explorar todo.

Este es el CLAUDE.md a nivel proyecto, va commiteado y aplica a quien abra este
repo. El personal tuyo, que aplica a todos tus proyectos, seria
~/.claude/CLAUDE.md (hoy no existe). Los dos se concatenan, no se pisan.

VA AQUI
  - Que es el proyecto y con que esta hecho: stack, decisiones grandes.
  - Los comandos del dia a dia: levantar, testear, lintear, desplegar.
  - Convenciones de codigo y de commits que no se deducen leyendo el repo.
  - Trampas: lo que alguien nuevo romperia sin saber que existia.
  - Correcciones que ya tuviste que repetir mas de una vez.

NO VA AQUI
  - Lo que se deduce leyendo el codigo o el git log.
  - Documentacion larga: enlazala, o importala con `@ruta` si debe estar
    siempre en contexto.
  - Estado temporal de la tarea de hoy.
  - Sedimento: si una regla ya no es cierta, borrala. Una regla vieja hace mas
    dano que ninguna.

REGLAS DE ORO
  - Menos de 200 lineas. Mas largo gasta mas contexto y se obedece menos.
    Ojo: lo que entra por un `@import` tambien cuenta.
  - Concreto y verificable. "Indentacion de 2 espacios", no "formatea bien".
  - Sin reglas que se contradigan: ante un choque Claude elige una al azar.
  - Empieza corto y agrega una regla cuando te descubras corrigiendo lo mismo
    dos veces. No lo escribas "por si acaso".

Este bloque es un comentario HTML: Claude Code los quita antes de inyectar el
archivo, asi que no gasta contexto. Las notas para humanos van aqui.
-->

# Albert-Efficient-Init

Toolkit de Claude Code que se integra en **cualquier otro repositorio** como
plugin: skills, subagentes, hooks, MCP y las reglas base de `CLAUDE.md`. Ese es el
alcance entero del proyecto. No es un libro de consulta ni una configuracion
personal de `~/.claude`: todo lo que se agregue aqui tiene que poder viajar a un
repo ajeno y servirle a su equipo.

El repo es **contenido puro**: no hay instalador ni build. Casi todo son
archivos Markdown y JSON que Claude Code carga como plugin; la unica excepcion
son los scripts de `plugin/hooks/`, que si son codigo y si tienen pruebas.

La documentacion de este repo esta en espanol. Mantenla asi.

## Reglas base

Las que este repo distribuye a otros proyectos, aplicadas aqui tambien:

@plugin/reglas-base.md

## Antes de afirmar como funciona Claude Code

El tema de este repo *es* la configuracion de Claude Code, asi que una
suposicion equivocada no se queda en un bug: se convierte en documentacion
equivocada que despues llega a otros repos.

**Verifica en la documentacion antes de afirmar** como funcionan los plugins,
las skills, los hooks, `settings.json`, los permisos o los imports de
`CLAUDE.md`. No respondas de memoria. La URL vigente es
`https://code.claude.com/docs/en/`; cada pagina tiene su version `.md` para
leerla con `curl`.

Supuestos que ya salieron falsos en este repo: `commands/*.md` esta marcado
legacy frente a `skills/<n>/SKILL.md`; `$HOME` es de solo lectura en
PowerShell 5.1; y un `CLAUDE.md` en la raiz de un plugin **no se carga**.

## Como esta armado

Dos capas, y es lo que mas se presta a error:

| Ruta | Que es | Llega a los repos destino |
|---|---|---|
| `.claude-plugin/marketplace.json` | El catalogo. Un solo plugin, `albert`, con `source: "./plugin"` | Si, es lo que registran |
| `plugin/` | El plugin. Todo lo que se distribuye vive aqui | Si, entero |
| `docs/`, `CLAUDE.md`, `README.md`, `deuda-tecnica.md` | Como trabajar en este repo | **No** |

Dentro de `plugin/`, cada pieza por su via:

| Pieza | Ruta | Como llega |
|---|---|---|
| Skills | `plugin/skills/<n>/SKILL.md` | Solas, como `/albert:<n>` |
| Subagentes | `plugin/agents/<n>.md` | Solos, como `@agent-albert:<n>` |
| Hooks | `plugin/hooks/hooks.json` | Solos. Los scripts se referencian con `${CLAUDE_PLUGIN_ROOT}` |
| MCP | `plugin/.mcp.json` | Solos. Hoy vacio a proposito |
| Reglas base | `plugin/reglas-base.md` | Solas: `hooks/reglas-base.js` las inyecta en cada sesion y cada subagente. **No** se copian al `CLAUDE.md` del repo destino |

Cada pieza tiene su guia en `docs/` con que merece guardarse ahi y que no. Si
vas a crear algo nuevo, leela antes: la confusion tipica es meter en `skills/`
algo que deberia ser un agente o un hook.

## Lo que no es obvio

- **Un merge a `main` es un release.** El plugin no declara `version` a
  proposito: asi los repos destino siguen los commits. No agregues `version` a
  `plugin.json` ni al `marketplace.json` salvo que se decida versionar, porque
  desde ese momento un commit sin subir la version no le llega a nadie.
  `claude plugin validate` avisa de que falta; es esperado.
- **No renombres el plugin `albert` ni el marketplace `albert-efficient-init`.**
  Son las claves que los repos destino tienen en su `.claude/settings.json`.
  Renombrar rompe todas las integraciones; si hiciera falta, va con el mapa
  `renames` del `marketplace.json`.
- **Nada dentro de `plugin/` puede salir de `plugin/`.** El plugin se copia a
  una cache y las rutas con `..` no cargan. Lo que compartan varias skills se
  referencia con `${CLAUDE_PLUGIN_ROOT}`.
- **Nada de `CLAUDE.md` ni `README.md` dentro de `plugin/`.** El primero no se
  carga y el validador lo marca; las guias de autor van en `docs/`.
- **Las reglas base no van en un `CLAUDE.md`.** Un plugin no puede aportar uno,
  asi que `plugin/reglas-base.md` llega por un hook `SessionStart` (y
  `SubagentStart`, porque los subagentes no ven el contexto de la sesion). El
  `CLAUDE.md` de la raiz lo importa, asi que editarlo cambia tambien como se
  comporta Claude aqui. Tope del hook: 10.000 caracteres; hay un test.
- **Instalar es commitear un archivo.** `instalar/settings.json` es lo unico
  que necesita un repo destino. Si algo nuevo obliga a un segundo paso, esta
  mal planteado: el objetivo del proyecto es integrarlo sin friccion.
- **No reintroduzcas un instalador.** El plugin es el mecanismo de
  distribucion; los scripts, las junctions y el modo global se quitaron a
  proposito. El motivo esta en la bitacora de `deuda-tecnica.md`.
- **Una skill no es un agente.** Una skill es un procedimiento que se inyecta
  en *esta* conversacion y admite bloques ` ```! `. Un agente corre en su
  propio contexto, no ve nada de la conversacion, y su cuerpo es un system
  prompt que **no ejecuta nada**. En un plugin, los agentes ignoran
  `hooks`, `mcpServers` y `permissionMode` del frontmatter.
- **Cada subagente carga los `CLAUDE.md` completos** salvo que lleve
  `omitClaudeMd: true`, y ademas reciben las reglas base por `SubagentStart`.
  Cada linea de `reglas-base.md` se paga en cada sesion y cada subagente de
  cada repo destino.

## Como se verifica lo que hay aqui

El plugin y el marketplace se validan con el CLI:

```bash
claude plugin validate .
claude plugin validate ./plugin
```

Los unicos tests son los de los hooks, porque un `PreToolUse` mal escrito
bloquea todas las herramientas **en todos los repos que integran el toolkit**:

```bash
node plugin/hooks/guards.test.js
```

Correlo siempre que toques un guard. Buena parte de sus 47 casos comprueban lo
que **no** debe bloquear, que es donde estan los errores caros: una version
anterior bloqueaba `git branch -d`, que es la variante segura, y el de secretos
tiene que dejar pasar los `.env.example`.

Para probar el plugin entero sin publicarlo: `claude --plugin-dir ./plugin`.

Los bloques ` ```! ` de una skill se ejecutan **antes** de que Claude la vea, y
**si salen != 0 abortan la invocacion entera**. Termina siempre en `true` y
protege cada linea con `||`. Antes de commitear una skill, extrae el bloque y
correlo:

```bash
awk '/^```!$/{f=1;next} f&&/^```$/{exit} f' plugin/skills/<nombre>/SKILL.md > /tmp/probe.sh
bash /tmp/probe.sh; echo "EXIT=$?"
```

En cuatro estados: repo normal con rama de trabajo, repo sin `main` ni
`master`, directorio que no es git, y repo sin ningun commit. Los cuatro deben
dar `EXIT=0`.

**Eso no basta.** Claude Code pasa el bloque por su chequeo de permisos antes
de correrlo, y rechaza cosas que `bash` acepta: grupos `{ ...; }`, pipes dentro
de un `if` de una linea, y cualquier ejecutable que no este en `allowed-tools`.
Las tres skills originales daban `EXIT=0` y ninguna corria. Invocala de verdad:
`claude -p "/albert:<nombre>" --plugin-dir ./plugin --max-turns 1` y busca
`permission check failed` en la salida. Detalle en `docs/comandos.md`.

## Entorno

Este toolkit corre en **las maquinas de cualquiera que integre el repo
destino**: Windows, macOS, Linux y sesiones remotas. Nada de lo que se agregue
aqui puede asumir un solo sistema.

- **Los hooks van en Node**, sin dependencias. Es lo unico del repo que se
  ejecuta, y un hook lo lanza el sistema operativo, no Claude Code: un `.ps1`
  no protege nada fuera de Windows. Rutas con `path.join`, nunca `C:\`.
- La maquina principal es **Windows con PowerShell 5.1 Desktop**, sin `pwsh` 7.
  Si escribes PowerShell para algo puntual, recuerda que ahi no hay `&&` como
  encadenador, ni ternarios, ni `??`, y que `$HOME` es de solo lectura.
- **`gh` CLI:** en la Mac si esta, autenticado; en la maquina Windows no.
  Sin `gh`, el PR se abre desde la web con el enlace que imprime el push.
- Las rutas reales del usuario llevan espacios. Cita siempre.

## Commits y cierre

- Mensajes en espanol, imperativo, una linea de asunto y cuerpo que explique el
  **por que**, no el que. Sin prefijos de herramienta.
- **Sin linea `Co-Authored-By`.** El historial no la usa; no la agregues.
- **`main` esta protegida:** no admite push directo ni force push, ni siquiera
  de administradores. Todo cambio va por rama y pull request:
  `git switch -c <rama>`, commit, `git push -u origin <rama>`,
  `gh pr create --fill`, `gh pr merge --merge`. El PR no exige aprobacion: el
  unico mantenedor no puede aprobarse a si mismo.
- Nunca hagas push ni mergees un PR sin confirmarlo antes con el usuario. Un
  merge a `main` le llega a todos los repos que integran el toolkit.
- El repo es **publico**. Nada de secretos, correos personales, rutas de la
  maquina ni nombres de otros repos privados en archivos, commits ni PRs. Los
  commits van con el correo `noreply` de GitHub.
- `deuda-tecnica.md` lo mantiene `/albert:finalizar`. Lo que quede a medias,
  sin verificar o decidido a medias va ahi, con `[M]` si requiere accion manual
  del usuario o `[A]` si un agente puede cerrarlo solo. No lo repitas en el chat
  si ya quedo escrito en el archivo.
