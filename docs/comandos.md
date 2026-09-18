# Agregar comandos

Un comando nuevo es un directorio con un `SKILL.md` dentro de
`plugins/albert/skills/`. Nada más. El instalador lo recoge solo y el
marketplace lo publica solo.

```bash
mkdir -p plugins/albert/skills/mi-comando
$EDITOR plugins/albert/skills/mi-comando/SKILL.md
bash install.sh --skills --force     # ya está disponible como /mi-comando
```

En una sesión abierta, corre `/reload-plugins` para que aparezca.

## De dónde sale el nombre

Depende de cómo lo instales, y conviene tenerlo claro:

| Instalación | Invocación |
|---|---|
| `install.sh --skills` (user) | `/mi-comando` |
| `install.sh --skills --scope project` | `/mi-comando` |
| `/plugin install albert@albert-efficient` | `/albert:mi-comando` |

Para skills personales y de proyecto el nombre del comando sale del **nombre del
directorio**, no del campo `name` del frontmatter. Para skills dentro de un
plugin siempre llevan el namespace del plugin.

La invocación no distingue mayúsculas: `/finalizar` y `/Finalizar` son lo mismo.

Si el mismo nombre existe en varios sitios, gana el personal
(`~/.claude/skills/`) sobre el del proyecto (`.claude/skills/`).

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
| `allowed-tools` | Pre-aprueba herramientas para no tener que confirmar a cada paso. |
| `model` / `effort` | Forzar modelo o nivel de esfuerzo. |
| `arguments` | Lista de nombres para usar `$nombre` en vez de `$1`. |

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
  plugins/albert/skills/mi-comando/SKILL.md > /tmp/probe.sh
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
- [ ] `bash install.sh --list` lo muestra.

## Publicarlo en el marketplace

Nada que hacer: `plugins/albert/skills/` ya es lo que el marketplace sirve.
Sube el `version` en `plugins/albert/.claude-plugin/plugin.json` y en
`.claude-plugin/marketplace.json` para que quien lo tenga instalado reciba la
actualización.

Si tienes el CLI a mano, valida antes de publicar:

```bash
claude plugin validate ./plugins/albert
```
