# hooks/

Comandos que Claude Code dispara solo en momentos concretos de la sesion: antes
de una herramienta, despues, al enviar tu un prompt, al terminar un turno.

Lo que los diferencia de todo lo demas del repo es que **son deterministas**.
Una regla en el `CLAUDE.md` se cumple casi siempre; un hook se cumple siempre.
Si algo tiene que pasar sin excepciones, no lo pidas en un prompt: ponlo aqui.

> **Son la excepcion al "solo pullea la carpeta".** No existe ninguna carpeta
> que Claude Code auto-cargue como hooks. El script puede vivir donde quieras,
> pero **siempre** hay que registrarlo con una entrada en un `settings.json`.
> Por eso esta carpeta guarda los scripts y este README guarda el bloque que
> hay que pegar.

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
- **Pruebalo antes de registrarlo.** Un `PreToolUse` mal escrito te bloquea
  todas las herramientas y hay que ir a mano al `settings.json` a quitarlo.
- **Rutas absolutas** si el hook es global; `${CLAUDE_PROJECT_DIR}/...` si vive
  dentro de un proyecto.

## Catalogo

| Hook | Evento | Que hace |
|---|---|---|
| [`guard-git-destructivo.ps1`](guard-git-destructivo.ps1) | `PreToolUse` / `Bash` | Bloquea `push --force`, `reset --hard`, `clean -f` y `branch -D`. Deja pasar `--force-with-lease`, `clean -n` y `branch -d`. |

Es el ejemplo de por que existen los hooks: `/finalizar` ya tiene escrito en su
prompt que nunca haga force push, y casi siempre lo cumple. El hook lo vuelve
imposible.

Falla abierto: si el JSON no parsea, deja pasar. Tiene pruebas en
[`guard-git-destructivo.test.ps1`](guard-git-destructivo.test.ps1), la mitad de
ellas dedicadas a comprobar lo que **no** debe bloquear:

```powershell
powershell -ExecutionPolicy Bypass -File hooks\guard-git-destructivo.test.ps1
```

Para activarlo, pega esto en tu `settings.json` con la ruta real del repo:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File C:/ruta/al/repo/hooks/guard-git-destructivo.ps1"
          }
        ]
      }
    ]
  }
}
```

Para desactivarlo, quita ese bloque. No hay otro interruptor.

## Donde registrarlo

Tres sitios, segun el alcance que quieras:

| Archivo | Alcance | Se commitea |
|---|---|---|
| `~/.claude/settings.json` | Todos tus repos | No, es tuyo |
| `<proyecto>/.claude/settings.json` | Ese repo, todo el equipo | Si |
| `<proyecto>/.claude/settings.local.json` | Ese repo, solo tu | No, va gitignoreado |

Se **mergea** con lo que el archivo ya tenga. No lo reemplaces entero, que ahi
viven tambien tus `permissions`.

- **`matcher`** filtra por herramienta. Los eventos que no son de herramienta lo
  ignoran.
- **En Windows** el `.ps1` no se ejecuta solo: invocalo con
  `powershell -NoProfile -File <ruta>`.

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

## La alternativa que si es file-drop

Si el hook solo tiene sentido **durante un flujo concreto**, no lo registres
global: declaralo en el frontmatter de la skill que lo necesita. Eso vive dentro
de `skills/` y por lo tanto si viaja con un `git pull`, sin tocar ningun
`settings.json`:

```yaml
---
name: mi-comando
description: ...
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "${CLAUDE_SKILL_DIR}/check.ps1"
---
```

El hook queda activo desde que invocas la skill y dura el resto de la sesion.
Usa `once: true` si solo debe correr la primera vez que coincida.

## Antes de commitear un hook

- [ ] Probado con el JSON real por stdin, no solo leido.
- [ ] Falla abierto ante entrada que no entiende.
- [ ] El `matcher` esta acotado a las herramientas que aplican.
- [ ] Si bloquea, el mensaje dice **por que** y **que hacer en su lugar**.
- [ ] Documentado en el catalogo de arriba, con su bloque JSON.
