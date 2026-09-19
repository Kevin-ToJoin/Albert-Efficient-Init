# Albert-Efficient-Init

Carpeta de comandos, hooks y reglas para Claude Code. Sin instalador: clonas el
repo, lo enganchas una vez, y a partir de ahí **actualizar es `git pull`**.

```
skills/     comandos como /finalizar      -> se enganchan a ~/.claude/skills
agents/     subagentes como auditor-deuda -> se enganchan a ~/.claude/agents
hooks/      scripts deterministas         -> requieren una entrada en settings.json
mcp/        plantillas de .mcp.json       -> se copian al proyecto que los quiera
rules/      CLAUDE.md + perfiles          -> se copian al proyecto que los quiera
docs/       cómo escribir lo de arriba
CLAUDE.md   cómo trabajar en este repo    -> importa la plantilla de rules/
```

Cada carpeta lleva su propio README con **qué merece guardarse ahí y qué no**,
para que la decisión de "¿esto es una skill, un agente o un hook?" no haya que
volver a razonarla cada vez.

## Engancharlo (una sola vez)

Clona donde quieras y enlaza `skills/` y `agents/` dentro de `~/.claude/`:

```powershell
git clone https://github.com/Kevin-ToJoin/Albert-Efficient-Init.git
New-Item -ItemType Junction -Path "$HOME\.claude\skills" -Target "<ruta-al-repo>\skills"
New-Item -ItemType Junction -Path "$HOME\.claude\agents" -Target "<ruta-al-repo>\agents"
```

En macOS o Linux:

```bash
git clone https://github.com/Kevin-ToJoin/Albert-Efficient-Init.git
ln -s "<ruta-al-repo>/skills" ~/.claude/skills
ln -s "<ruta-al-repo>/agents" ~/.claude/agents
```

Y ya: `/finalizar` y `@agent-auditor-deuda` funcionan en **cualquier** repo que
abras. Cuando agregues o edites uno, `git pull` y está disponible al instante —
no hay copia que re-hacer.

> Una junction de Windows no necesita permisos de admin y funciona entre
> unidades distintas (el repo en `E:`, tu home en `C:`). Borrarla con
> `(Get-Item "$HOME\.claude\skills").Delete()` no toca el repo.

**Si `~/.claude/skills` ya existe** como carpeta real, el enlace falla. Mueve lo
que tengas dentro al `skills/` del repo y borra la carpeta original, o sáltate la
junction y copia la carpeta a mano (perdiendo el `git pull`).

**Si prefieres un solo repo** en vez de global, el mismo `skills/` funciona
copiado a `<proyecto>/.claude/skills/`. Ahí el comando existe solo en ese repo y,
si lo commiteas, le llega a todo el equipo.

## Los comandos

### `/finalizar`

Cierre de sesión de trabajo. Hace tres cosas y te molesta lo mínimo posible:

1. **Registra la deuda técnica** en el `deuda-tecnica.md` del repo: lo que quedó
   a medias, los atajos, los `TODO`/`FIXME` del código que tocaste, los tests que
   faltan. Append, nunca sobrescribe.
2. **Commitea y mergea** la rama actual a la base (`main`, si no `master`, si no
   la que apunte `origin/HEAD`) y hace push si hay remoto.
3. **Reporta solo lo que tú tienes que hacer a mano.** Si no hay nada, responde
   `OK` y ya. Sin resúmenes, sin "he mergeado exitosamente", sin siguientes pasos.

```
/finalizar
/finalizar "refactor del cliente de pagos"     # mensaje de commit explícito
```

Te reporta: conflictos de merge, push rechazado o rama protegida, credenciales
que faltan, decisiones que no le tocan, cosas fuera del repo. No te reporta lo
que ya quedó escrito en `deuda-tecnica.md` (refactors, tests, TODOs).

Nunca hace `push --force`, y ante un conflicto aborta el merge, te devuelve a tu
rama y te lo dice en lugar de resolverlo por su cuenta.

## Los subagentes

Corren en **su propia ventana de contexto** y te devuelven solo el resultado,
para que el trabajo pesado de exploración no te ensucie la conversación
principal.

### `@agent-auditor-deuda`

Barre el repo buscando `TODO`/`FIXME`/`HACK`, tests saltados y trabajo a
medias, lo cruza contra `deuda-tecnica.md` y te reporta **solo lo que no está
registrado**. Complementa a `/finalizar`, que solo conoce la sesión actual.

Si no encuentra nada responde `Todo registrado.` y ya. No escribe en ningún
archivo: reporta, y quien registra es `/finalizar`.

El formato, el frontmatter completo y las trampas están en
[agents/README.md](agents/README.md).

## Los hooks

Lo que los distingue de todo lo demás: **son deterministas**. Una regla del
`CLAUDE.md` se cumple casi siempre; un hook se cumple siempre.

### `guard-git-destructivo.ps1`

Bloquea `git push --force`, `reset --hard`, `clean -f` y `branch -D` antes de
que se ejecuten, y le explica a Claude por qué y qué hacer en su lugar. Deja
pasar las variantes seguras: `--force-with-lease`, `clean -n`, `branch -d`.

Es el ejemplo de por qué existen los hooks: `/finalizar` ya lleva escrito en su
prompt que nunca haga force push, y casi siempre lo cumple. El hook lo vuelve
imposible.

Falla abierto — si no entiende su entrada, deja pasar. Tiene 20 pruebas, la
mitad dedicadas a comprobar lo que **no** debe bloquear.

A diferencia de los comandos, **no basta con dejar el archivo en la carpeta**:
hay que registrarlo en un `settings.json`. El bloque para pegar y la guía de
cuándo escribir un hook están en [hooks/README.md](hooks/README.md).

## Los MCP

Conectan Claude Code con sistemas de fuera: issues, bases de datos, documentos,
APIs internas. No se enganchan con junction — la configuración vive en un
`.mcp.json` del proyecto o en `~/.claude.json`, así que [mcp/](mcp/) guarda
plantillas que copias.

Hay una [plantilla con los cuatro transportes](mcp/mcp.json.ejemplo) y, en
[mcp/README.md](mcp/README.md), los tres alcances y la trampa de los secretos:
las variables con `TOKEN`, `KEY`, `SECRET`, `PASSWORD` o `AUTH` en el nombre
**no se expanden** en `url` ni `headers` de servidores remotos, a propósito.

## Las reglas

`CLAUDE.md` + perfiles de reglas token-efficient, pensados para vivir
**gitignoreados** en el proyecto destino: reflejan tu preferencia personal sin
imponérsela a nadie. Se copian a mano, son cuatro archivos. Ver
[rules/README.md](rules/README.md).

## Agregar lo tuyo

Un comando nuevo es un directorio con un `SKILL.md` dentro de `skills/`. Nada
más: la junction hace que exista al instante. El formato, los argumentos, la
inyección de contexto con `` !`cmd` `` y el checklist antes de commitear están en
[docs/comandos.md](docs/comandos.md).

## Atribución

Las reglas de eficiencia derivan de ideas de
[drona23/claude-token-efficient](https://github.com/drona23/claude-token-efficient)
(MIT). Ver [ATTRIBUTION.md](ATTRIBUTION.md).

## Licencia

MIT. Ver [LICENSE](LICENSE).
