# Agregar comandos

Un comando nuevo es un directorio con un `SKILL.md` dentro de `plugin/skills/`.
Nada más:

```bash
mkdir -p plugin/skills/mi-comando
$EDITOR plugin/skills/mi-comando/SKILL.md
```

Para probarlo antes de publicarlo, arranca Claude Code con
`claude --plugin-dir ./plugin`. En una sesión que ya estaba abierta, corre
`/reload-plugins` para que aparezca. Cuando llega a `main`, les llega a todos
los repos que integran el toolkit.

## De dónde sale el nombre

Del **nombre del directorio**, con el nombre del plugin como prefijo:
`plugin/skills/mi-comando/` → `/albert:mi-comando`.

El prefijo evita choques: un `/finalizar` que el repo destino tenga en su
propio `.claude/skills/` convive con `/albert:finalizar` sin pisarse.

## Formato

````markdown
---
name: mi-comando
description: Qué hace y cuándo usarlo. Claude lee esto para decidir si aplica.
argument-hint: "[lo que espera]"
disable-model-invocation: true
allowed-tools: Bash(git *) Read Write Edit
---

# /albert:mi-comando

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
| `hooks` | Hooks activos desde que se invoca la skill. Ver [hooks.md](hooks.md). |

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

Errores reales que costaron una iteración escribiendo `/albert:finalizar`:

- `git log HEAD --not main master` falla entero si `master` no existe, así que
  devolvía vacío en cualquier repo moderno. Hay que encadenar con `||`, no
  pasar las dos ramas juntas.
- `git remote` sin remotos no falla: imprime nada y sale 0. Un `|| echo` no se
  dispara nunca. Hace falta `| grep .` en medio.
- `git rev-parse --abbrev-ref HEAD` en un repo sin commits imprime `HEAD` *y*
  sale 128. Para detectar la rama usa `git symbolic-ref --short -q HEAD`, que
  funciona en repos vacíos.

### Claude Code revisa el bloque antes de correrlo

Antes de ejecutar un bloque `!`, Claude Code lo pasa por el mismo chequeo de
permisos que cualquier comando de Bash. Si no lo aprueba, **el comando no
corre** y el modelo ni se entera. En una sesion interactiva te pide permiso; en
una no interactiva simplemente no pasa nada. Tres reglas que salieron de
encontrarlo en las tres skills del toolkit, que `bash` daba por buenas:

- **Sin grupos `{ ...; }`.** Una llave con comillas dentro se rechaza como
  "expansion obfuscation", y un grupo sin comillas como `compound_statement`.
  Usa `if ... fi` de una linea o lineas sueltas con `|| true`.
- **Sin pipes dentro de un `if` de una linea.** El analizador corta mal
  `if ...; then a | b; else ...; fi` y pide aprobacion para un trozo sin
  sentido. Saca el pipe fuera del `if`.
- **Cada ejecutable del bloque en `allowed-tools`.** `grep`, `head`, `cut`: si
  no estan como `Bash(grep *)`, no se aprueban solos.

Pruébalo antes de commitear, extrayendo el bloque tal cual:

```bash
awk '/^```!$/{f=1;next} f&&/^```$/{exit} f' \
  plugin/skills/mi-comando/SKILL.md > /tmp/probe.sh
bash /tmp/probe.sh; echo "EXIT=$?"
```

Corre eso en al menos cuatro estados: repo normal con rama de trabajo, repo sin
`main` ni `master`, directorio que no es repo git, y repo recién inicializado sin
commits. Los cuatro deben salir `EXIT=0`.

Eso prueba el shell, no el chequeo de Claude Code. Para ese, invócalo de verdad
con el plugin local, en una carpeta de prueba:

```bash
claude -p "/albert:mi-comando" --plugin-dir <ruta-al-repo>/plugin \
  --permission-mode acceptEdits --max-turns 1 --output-format stream-json --verbose
```

Si la salida trae un `local-command-stderr` con `Shell command permission check
failed`, el bloque no paso: el motivo viene al final de ese mensaje.

## Checklist antes de commitear un comando

- [ ] `claude plugin validate ./plugin` pasa.
- [ ] Los bloques `!` salen 0 en los cuatro estados de arriba.
- [ ] Invocado con `claude -p` y `--plugin-dir` sin `permission check failed`.
- [ ] `disable-model-invocation: true` si el comando escribe, commitea o empuja.
- [ ] La `description` dice cuándo usarlo, no solo qué hace.
- [ ] El comando dice explícitamente **qué no reportar**. Si no, Claude resume de
      más y el comando deja de ser útil.
- [ ] Nada destructivo sin salida de escape: nada de `push --force`, nada de
      resolver conflictos por su cuenta, nada de borrar ramas sin pedirlo.
- [ ] Probado invocándolo de verdad en un repo real, no solo leído.
