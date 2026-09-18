# Agregar comandos

Un comando nuevo es un directorio con un `SKILL.md` dentro de `skills/`. Nada
más:

```bash
mkdir -p skills/mi-comando
$EDITOR skills/mi-comando/SKILL.md
```

Si enganchaste `skills/` con una junction (ver el [README](../README.md)), el
comando ya existe: no hay que copiar ni instalar nada. En una sesión que ya
estaba abierta, corre `/reload-plugins` para que aparezca.

## De dónde sale el nombre

Del **nombre del directorio**, no del campo `name` del frontmatter:
`skills/mi-comando/` → `/mi-comando`.

La invocación no distingue mayúsculas: `/finalizar` y `/Finalizar` son lo mismo.
Si el mismo nombre existe en varios sitios, gana el personal
(`~/.claude/skills/`) sobre el del proyecto (`<proyecto>/.claude/skills/`).

## Formato

````markdown
---
name: mi-comando
description: Qué hace y cuándo usarlo. Claude lee esto para decidir si aplica.
argument-hint: "[lo que espera]"
disable-model-invocation: true
allowed-tools: Bash(git *) Read Write Edit
---

# /mi-comando

Argumentos recibidos: `$ARGUMENTS`

## Contexto

```!
git status --short 2>/dev/null || true
true
```

## Procedimiento

1. ...
2. ...

## Reporte

Qué decirle al usuario, y qué callarse.
````

### Frontmatter

| Campo | Para qué |
|---|---|
| `description` | Cuándo aplica. Es lo que Claude lee para auto-invocarlo. |
| `argument-hint` | Pista en el autocompletado. |
| `disable-model-invocation` | `true` = solo tú lo invocas. **Úsalo en todo comando con efectos secundarios** (commit, merge, push, deploy). |
| `allowed-tools` | Pre-aprueba herramientas para no confirmar a cada paso. |
| `model` / `effort` | Forzar modelo o nivel de esfuerzo. |
| `arguments` | Lista de nombres para usar `$nombre` en vez de `$1`. |
| `hooks` | Hooks activos desde que se invoca la skill. Ver [hooks/](../hooks/README.md). |

### Argumentos

- `$ARGUMENTS` — todo lo que escribiste después del comando.
- `$0`, `$1`, `$2` — por posición.
- `$nombre` — si declaraste `arguments: [nombre, otro]` en el frontmatter.
- `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_SESSION_ID}`.

## Inyección de contexto: la trampa importante

Un bloque `` !`cmd` `` o un bloque cercado con `` ```! `` se ejecuta **antes** de
que Claude vea el comando, y su salida se pega en el prompt. Sirve para darle el
estado real del repo sin gastar un turno.

> **Si el bloque sale con código distinto de cero, se aborta la invocación
> entera del comando.**

Por eso todo comando de este repo termina sus bloques con `true` y protege cada
línea:

```bash
git remote 2>/dev/null | grep . || echo "(sin remoto)"
git log --oneline HEAD --not main 2>/dev/null \
  || git log --oneline HEAD --not master 2>/dev/null \
  || echo "(sin rama base local)"
true
```

Errores reales que costaron una iteración escribiendo `/finalizar`:

- `git log HEAD --not main master` falla entero si `master` no existe, así que
  devolvía vacío en cualquier repo moderno. Hay que encadenar con `||`, no
  pasar las dos ramas juntas.
- `git remote` sin remotos no falla: imprime nada y sale 0. Un `|| echo` no se
  dispara nunca. Hace falta `| grep .` en medio.
- `git rev-parse --abbrev-ref HEAD` en un repo sin commits imprime `HEAD` *y*
  sale 128. Para detectar la rama usa `git symbolic-ref --short -q HEAD`, que
  funciona en repos vacíos.

Pruébalo antes de commitear, extrayendo el bloque tal cual:

```bash
awk '/^```!$/{f=1;next} f&&/^```$/{exit} f' \
  skills/mi-comando/SKILL.md > /tmp/probe.sh
bash /tmp/probe.sh; echo "EXIT=$?"
```

Corre eso en al menos cuatro estados: repo normal con rama de trabajo, repo sin
`main` ni `master`, directorio que no es repo git, y repo recién inicializado sin
commits. Los cuatro deben salir `EXIT=0`.

## Checklist antes de commitear un comando

- [ ] Los bloques `!` salen 0 en los cuatro estados de arriba.
- [ ] `disable-model-invocation: true` si el comando escribe, commitea o empuja.
- [ ] La `description` dice cuándo usarlo, no solo qué hace.
- [ ] El comando dice explícitamente **qué no reportar**. Si no, Claude resume de
      más y el comando deja de ser útil.
- [ ] Nada destructivo sin salida de escape: nada de `push --force`, nada de
      resolver conflictos por su cuenta, nada de borrar ramas sin pedirlo.
- [ ] Probado invocándolo de verdad en un repo real, no solo leído.
