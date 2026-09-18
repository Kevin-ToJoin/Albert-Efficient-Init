# hooks/

Scripts que Claude Code dispara solo cuando pasa algo en la sesión: antes de una
herramienta, al terminar un turno, al arrancar.

> **Los hooks son la excepción al "solo pullea la carpeta".** No existe ninguna
> carpeta que Claude Code auto-cargue como hooks. El script puede vivir donde
> quieras, pero **siempre** hay que registrarlo con una entrada en un
> `settings.json`. Por eso esta carpeta guarda los scripts y este README guarda
> el bloque que hay que pegar.

## Registrarlo

Tres sitios posibles, según el alcance que quieras:

| Archivo | Alcance | ¿Se commitea? |
|---|---|---|
| `~/.claude/settings.json` | Todos tus repos | No, es tuyo |
| `<proyecto>/.claude/settings.json` | Ese repo, todo el equipo | Sí |
| `<proyecto>/.claude/settings.local.json` | Ese repo, solo tú | No, va gitignoreado |

La forma del bloque es siempre la misma. Se mergea con lo que el archivo ya
tenga — no lo reemplaces entero, que ahí viven también tus `permissions`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File C:/ruta/al/repo/hooks/mi-hook.ps1"
          }
        ]
      }
    ]
  }
}
```

- **`matcher`** filtra por herramienta (`Bash`, `Write|Edit`, `.*` para todas).
  Los eventos que no son de herramienta lo ignoran.
- **La ruta del comando** tiene que ser absoluta si el hook es global. Dentro de
  un proyecto usa `${CLAUDE_PROJECT_DIR}/.claude/hooks/x.ps1`, que Claude Code
  expande solo.
- **En Windows** el script no se ejecuta por sí mismo: invócalo con
  `powershell -NoProfile -File <ruta>`.

## Eventos útiles

| Evento | Cuándo dispara | Para qué sirve |
|---|---|---|
| `PreToolUse` | Antes de ejecutar una herramienta | Bloquear comandos peligrosos, pedir confirmación |
| `PostToolUse` | Después de ejecutarla | Formatear, lintear, correr tests al guardar |
| `UserPromptSubmit` | Al enviar tú un mensaje | Inyectar contexto, validar |
| `Stop` | Al terminar Claude su turno | Notificarte, sonido, resumen |
| `SessionStart` | Al abrir sesión | Cargar estado, avisar de algo del repo |

Hay bastantes más (`PermissionRequest`, `PreCompact`, `SubagentStop`,
`FileChanged`…). La lista completa está en la
[doc de hooks](https://code.claude.com/docs/en/hooks).

## La alternativa que sí es file-drop

Si el hook solo tiene sentido **durante un flujo concreto**, no lo registres
global: decláralo en el frontmatter de la skill que lo necesita. Eso vive dentro
de `skills/` y por lo tanto sí viaja con un `git pull`, sin tocar ningún
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

El hook queda activo desde que invocas la skill y dura el resto de la sesión.
Usa `once: true` si solo debe correr la primera vez que coincida.

## Agregar un hook aquí

1. Deja el script en esta carpeta (`hooks/mi-hook.ps1`).
2. **Pruébalo a mano antes de registrarlo.** Un hook roto en `PreToolUse` puede
   bloquearte todas las herramientas.
3. Documenta abajo qué hace y pega su bloque JSON.

## Catálogo

Todavía ninguno. Esta carpeta existe para cuando haga falta.
