# Hooks

Comandos que Claude Code dispara solo en momentos concretos de la sesion: antes
de una herramienta, despues, al enviar tu un prompt, al terminar un turno.

Lo que los diferencia de todo lo demas del repo es que **son deterministas**.
Una regla en el `CLAUDE.md` se cumple casi siempre; un hook se cumple siempre.
Si algo tiene que pasar sin excepciones, no lo pidas en un prompt: ponlo aqui.

> Viven en `plugin/hooks/`: los scripts y el `hooks.json` que los registra.
> Como van dentro del plugin, **se activan solos** en todo repo que integre el
> toolkit, sin tocar ningun `settings.json`. Por lo mismo, un hook roto se
> rompe en todos esos repos a la vez.

## Que guardar aqui

### Va aqui

- **Lo que tiene que pasar siempre.** Formatear despues de cada edicion,
  registrar cada comando ejecutado, correr el linter al guardar.
- **Bloqueos duros.** Impedir escrituras en produccion, comandos destructivos,
  commits a `main`. Lo que quieres *garantizado*, no *sugerido*.
- **Avisos.** Notificarte cuando Claude termina, para no quedarte mirando.

### No va aqui

- **Nada que requiera criterio.** Un hook no razona: corre un comando y mira el
  codigo de salida. Si la decision depende del contexto, es una regla del
  `CLAUDE.md` o una skill.
- **Nada lento.** Corre en cada evento que coincida con el matcher. Un hook de
  dos segundos en `PostToolUse` se nota en cada edicion.
- **Nada que falle cerrado sin querer.** Un `PreToolUse` que revienta y bloquea
  te deja sin poder trabajar. Salvo que sea un guard deliberado, ante la duda
  sal con 0.

### Reglas de oro

- **Acota con el `matcher`.** `"Bash"` o `"Write|Edit"`, no `".*"`, salvo que de
  verdad aplique a todo.
- **Falla abierto.** Si el hook no entiende su entrada, que salga 0 y deje
  pasar. Un guard roto que bloquea todo es peor que no tener guard.
- **El mensaje de bloqueo lo lee Claude**, no tu. Escribelo para el: por que se
  bloqueo y que hacer en su lugar.
- **Pruebalo antes de publicarlo.** Un `PreToolUse` mal escrito bloquea todas
  las herramientas de todos los repos que integran el toolkit, hasta que alguien
  desactive el plugin.
- **Rutas con `${CLAUDE_PLUGIN_ROOT}`**, nunca absolutas ni relativas: el
  plugin se copia a una cache cuya ruta cambia en cada actualizacion.

## Catalogo

| Hook | Evento | Que hace |
|---|---|---|
| [`guard-git-destructivo.js`](../plugin/hooks/guard-git-destructivo.js) | `PreToolUse` / `Bash` | Bloquea `push --force`, `reset --hard`, `clean -f` y `branch -D`. Deja pasar `--force-with-lease`, `clean -n` y `branch -d`. |
| [`guard-secretos.js`](../plugin/hooks/guard-secretos.js) | `PreToolUse` / `Bash` | Impide stagear o commitear `.env`, `*.pem`, `id_rsa`, `credentials.json`, y bloquea comandos con un token literal dentro. Deja pasar `.env.example`. |
| [`reglas-base.js`](../plugin/hooks/reglas-base.js) | `SessionStart` y `SubagentStart` | Inyecta `plugin/reglas-base.md` en cada sesion y en cada subagente. Es como llegan las reglas base a los repos integrados, sin copiarlas a su `CLAUDE.md`. |

Los dos fallan abierto: si el JSON no parsea, dejan pasar. Y los dos comparten
pruebas, donde buena parte de los casos comprueban lo que **no** deben
bloquear, que es donde estan los errores caros:

```bash
node plugin/hooks/guards.test.js
```

### `guard-git-destructivo.js`

Es el ejemplo de por que existen los hooks: `/albert:finalizar` ya tiene escrito en su
prompt que nunca haga force push, y casi siempre lo cumple. El hook lo vuelve
imposible.

### `guard-secretos.js`

Mira los `git add` y `git commit` y bloquea dos cosas: archivos de credenciales
y secretos escritos en el propio comando. Revisa tambien lo que ya esta en el
index, que es como se filtra un `.env` de verdad: con un `git add .` y a correr.

Las plantillas pasan a proposito. Un `.env.example` esta hecho para commitearse,
y un guard que lo bloquea acaba desactivado.

Es la version determinista de `albert:perfil-seguridad`. La regla se
cumple casi siempre; el hook hace que un secreto no pueda llegar al historial,
que es lo unico que importa: una vez commiteado hay que rotarlo aunque lo
borres.

### Como se registran

En [`plugin/hooks/hooks.json`](../plugin/hooks/hooks.json). Los dos comparten
matcher, asi que van en la misma entrada:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/guard-git-destructivo.js\""
          },
          {
            "type": "command",
            "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/guard-secretos.js\""
          }
        ]
      }
    ]
  }
}
```

Es la **forma shell**, la que ya se verifico en una sesion real. Las comillas
alrededor de la ruta importan: la cache del plugin puede tener espacios en
Windows. La doc recomienda tambien la forma exec (`command` + `args`), que no
pasa por ningun shell; esta pendiente de probar.

Un repo destino que no quiera los guards no tiene interruptor por hook:
desactiva el plugin entero para si con `/plugin`.

## Por que estan en Node y no en bash o PowerShell

Un hook no lo ejecuta Claude Code: Claude Code decide cuando, y lanza un
**proceso del sistema operativo** con lo que pongas en `command`. Por eso el
lenguaje importa, y por eso un `.ps1` no protege nada en un Mac: ahi no hay
`powershell.exe` que arrancar.

Como este toolkit se usa desde varias maquinas y desde sesiones remotas, los
guards estan en Node:

- **Una sola implementacion** para Windows, macOS y Linux. Mantener un `.sh` y
  un `.ps1` en paralelo es la misma carga de paridad que hizo insoportable el
  instalador viejo.
- **`JSON.parse` de verdad.** Sacar un campo de un JSON con `sed` o `grep` es
  fragil, y en un guard de seguridad lo fragil falla abierto sin avisar.
- **Sin dependencias.** Solo libreria estandar: nada de `jq`, que no viene
  instalado casi en ningun sitio.
- La doc oficial recomienda justo este patron, `node` + script en forma exec,
  para hooks que tienen que funcionar en varios sistemas.

Lo unico que hace falta en la maquina es Node. Si escribes un hook nuevo,
mantenlo asi salvo que solo lo vayas a usar en un sitio.

## Eventos utiles

| Evento | Cuando dispara | Para que |
|---|---|---|
| `PreToolUse` | Antes de ejecutar una herramienta | Bloquear lo peligroso |
| `PostToolUse` | Despues de ejecutarla | Formatear, lintear, correr tests |
| `UserPromptSubmit` | Al enviar tu un mensaje | Inyectar contexto, validar |
| `Stop` | Al terminar Claude su turno | Notificarte, sonido, resumen |
| `SessionStart` | Al abrir sesion | Cargar estado, avisar de algo del repo |

Hay bastantes mas (`PermissionRequest`, `PreCompact`, `SubagentStop`,
`FileChanged`...). La lista completa esta en la
[doc de hooks](https://code.claude.com/docs/en/hooks).

## Codigos de salida en `PreToolUse`

| Codigo | Efecto |
|---|---|
| `0` | Sigue el flujo normal de permisos |
| `2` | **Bloquea** la llamada. El stderr se le devuelve a Claude como motivo |
| Otro | Error no bloqueante: se te muestra pero no detiene nada |

Tambien se puede bloquear saliendo con 0 y escribiendo JSON en stdout con
`permissionDecision: "deny"` y su `permissionDecisionReason`. El `exit 2` es mas
simple y gana siempre: ni un `"allow"` lo revierte.

## Hooks que solo aplican durante una skill

Lo que va en `hooks.json` corre siempre, en cada sesion de cada repo destino.
Si el hook solo tiene sentido **durante un flujo concreto**, no lo pongas ahi:
declaralo en el frontmatter de la skill que lo necesita.

```yaml
---
name: mi-comando
description: ...
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "node ${CLAUDE_SKILL_DIR}/check.js"
---
```

El hook queda activo desde que invocas la skill y dura el resto de la sesion.
Usa `once: true` si solo debe correr la primera vez que coincida.

## Antes de commitear un hook

- [ ] Probado con el JSON real por stdin, no solo leido. Agrega sus casos a
      `guards.test.js` y corre `node plugin/hooks/guards.test.js`.
- [ ] Falla abierto ante entrada que no entiende.
- [ ] El `matcher` esta acotado a las herramientas que aplican.
- [ ] Si bloquea, el mensaje dice **por que** y **que hacer en su lugar**.
- [ ] Sin nada especifico de un sistema operativo: rutas con `path.join`, nada
      de `C:\`, nada de comandos que solo existan en uno.
- [ ] Registrado en `plugin/hooks/hooks.json` con `${CLAUDE_PLUGIN_ROOT}`, y
      `claude plugin validate ./plugin` pasa.
- [ ] Documentado en el catalogo de arriba.
