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

Toolkit personal de comandos, subagentes, hooks y reglas para Claude Code. El
repo es **contenido puro**: no hay instalador ni build. Casi todo son archivos
Markdown que Claude Code carga desde otro sitio; la unica excepcion son los
scripts de `hooks/`, que si son codigo y si tienen pruebas.

La documentacion de este repo esta en espanol. Mantenla asi.

## Reglas base

Las que este repo distribuye a otros proyectos, aplicadas aqui tambien:

@rules/CLAUDE-root-template.md

Con una correccion de ruta: aqui los perfiles viven en `rules/Efficiency/`, no
en `Efficiency/`.

## Antes de afirmar como funciona Claude Code

El tema de este repo *es* la configuracion de Claude Code, asi que una
suposicion equivocada no se queda en un bug: se convierte en documentacion
equivocada que despues se copia a otros repos.

**Verifica en la documentacion antes de afirmar** como funcionan las skills,
los hooks, `settings.json`, los permisos o los imports de `CLAUDE.md`. No
respondas de memoria. La URL vigente es `https://code.claude.com/docs/en/` —
las de `docs.claude.com/en/docs/claude-code/` redirigen ahi.

Tres supuestos que ya salieron falsos en este repo: `commands/*.md` esta
marcado legacy frente a `skills/<n>/SKILL.md`; `$HOME` es de solo lectura en
PowerShell 5.1; y los hooks no pueden ser file-drop, siempre necesitan una
entrada en `settings.json`.

## Cinco carpetas, tres mecanicas distintas

Es lo que mas se presta a error. Cada una llega a Claude Code por una via
diferente:

| Carpeta | Como llega | Implicacion |
|---|---|---|
| `skills/` | Junction: `~/.claude/skills` apunta aqui | Editar un `SKILL.md` cambia el comando **en vivo y en todos los repos** del usuario |
| `agents/` | Junction: `~/.claude/agents` apunta aqui | Igual que las skills. Los archivos sin `name` en el frontmatter se ignoran como documentacion |
| `hooks/` | No llega sola | Necesita una entrada en `settings.json`. No existe carpeta auto-cargable |
| `mcp/` | No llega sola | Se copia a `.mcp.json` del proyecto, o se registra con `claude mcp add` |
| `rules/` | No llega sola | Se copia a mano al proyecto que la quiera |

Cada una tiene su `README.md` con que merece guardarse ahi y que no. Si vas a
crear algo nuevo, leelo antes: la confusion tipica es meter en `skills/` algo
que deberia ser un agente o un hook.

## Lo que no es obvio

- **No reintroduzcas un instalador.** Habia cinco scripts, un marketplace y un
  plugin; se borraron a proposito y se cambiaron por la junction. El motivo
  esta en la bitacora de `deuda-tecnica.md`. Actualizar es `git pull`.
- **Un comando es un directorio con `SKILL.md`**, no un `.md` suelto. El nombre
  del comando sale del directorio, no del campo `name` del frontmatter.
- **`rules/CLAUDE-root-template.md` se llama asi a proposito.** Si se llamara
  `CLAUDE.md`, Claude Code lo auto-cargaria al trabajar dentro de `rules/`. No
  lo renombres. Ademas el `CLAUDE.md` de la raiz lo importa, asi que editarlo
  cambia tambien como se comporta Claude aqui.
- **Los hooks tienen una alternativa file-drop**: declararlos en el frontmatter
  de una skill. Esos si viajan con un `git pull` y no tocan ningun
  `settings.json`.
- **Una skill no es un agente.** Una skill es un procedimiento que se inyecta
  en *esta* conversacion y admite bloques ` ```! `. Un agente corre en su
  propio contexto, no ve nada de la conversacion, y su cuerpo es un system
  prompt que **no ejecuta nada**: los bloques `!` ahi no hacen lo que parece.
- **Cada subagente carga los `CLAUDE.md` completos** salvo que lleve
  `omitClaudeMd: true`. Este archivo entra en su contexto tambien, asi que
  mantenerlo corto importa mas de lo que parece.

## Como se verifica lo que hay aqui

Los unicos tests son los de los hooks, porque un `PreToolUse` mal escrito
bloquea todas las herramientas:

```bash
node hooks/guards.test.js
```

Correlo siempre que toques un guard. Buena parte de sus 47 casos comprueban lo
que **no** debe bloquear, que es donde estan los errores caros: una version
anterior bloqueaba `git branch -d`, que es la variante segura, y el de secretos
tiene que dejar pasar los `.env.example`.

Lo demas se verifica a mano. Los bloques ` ```! ` de una skill se ejecutan
**antes** de que Claude la vea, y **si salen != 0 abortan la invocacion
entera**. Termina siempre en `true` y protege cada linea con `||`.

Antes de commitear un comando, extrae el bloque y correlo:

```bash
awk '/^```!$/{f=1;next} f&&/^```$/{exit} f' skills/<nombre>/SKILL.md > /tmp/probe.sh
bash /tmp/probe.sh; echo "EXIT=$?"
```

En cuatro estados: repo normal con rama de trabajo, repo sin `main` ni
`master`, directorio que no es git, y repo sin ningun commit. Los cuatro deben
dar `EXIT=0`.

## Entorno

Este toolkit se usa desde **varias maquinas** (Windows, macOS, Linux) y desde
sesiones remotas. Nada de lo que se agregue aqui puede asumir un solo sistema.

- **Los hooks van en Node**, sin dependencias. Es lo unico del repo que se
  ejecuta, y un hook lo lanza el sistema operativo, no Claude Code: un `.ps1`
  no protege nada fuera de Windows. Rutas con `path.join`, nunca `C:\`.
- La maquina principal es **Windows con PowerShell 5.1 Desktop**, sin `pwsh` 7.
  Si escribes PowerShell para algo puntual, recuerda que ahi no hay `&&` como
  encadenador, ni ternarios, ni `??`, y que `$HOME` es de solo lectura.
- **Sin `gh` CLI.** No hay flujo de PRs desde aqui: commit local y push.
- Las rutas reales del usuario llevan espacios. Cita siempre.

## Commits y cierre

- Mensajes en espanol, imperativo, una linea de asunto y cuerpo que explique el
  **por que**, no el que. Sin prefijos de herramienta.
- **Sin linea `Co-Authored-By`.** El historial no la usa; no la agregues.
- Nunca hagas push sin confirmarlo antes con el usuario.
- `deuda-tecnica.md` lo mantiene el comando `/finalizar`. Lo que quede a medias,
  sin verificar o decidido a medias va ahi, con `[M]` si requiere accion manual
  del usuario o `[A]` si un agente puede cerrarlo solo. No lo repitas en el chat
  si ya quedo escrito en el archivo.
