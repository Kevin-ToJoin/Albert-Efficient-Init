# Albert-Efficient-Init

Carpeta de comandos, hooks y reglas para Claude Code. Sin instalador: clonas el
repo, lo enganchas una vez, y a partir de ahí **actualizar es `git pull`**.

```
skills/     comandos como /finalizar     -> se enganchan a ~/.claude/skills
hooks/      scripts + cómo registrarlos  -> requieren una entrada en settings.json
rules/      CLAUDE.md + perfiles         -> se copian al proyecto que los quiera
docs/       cómo escribir lo de arriba
CLAUDE.md   cómo trabajar en este repo   -> importa la plantilla de rules/
```

## Engancharlo (una sola vez)

Clona donde quieras y enlaza `skills/` dentro de `~/.claude/`:

```powershell
git clone https://github.com/Kevin-ToJoin/Albert-Efficient-Init.git
New-Item -ItemType Junction -Path "$HOME\.claude\skills" -Target "<ruta-al-repo>\skills"
```

En macOS o Linux:

```bash
git clone https://github.com/Kevin-ToJoin/Albert-Efficient-Init.git
ln -s "<ruta-al-repo>/skills" ~/.claude/skills
```

Y ya: `/finalizar` funciona en **cualquier** repo que abras. Cuando agregues o
edites un comando, `git pull` y está disponible al instante — no hay copia que
re-hacer.

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

## Los hooks

Un hook dispara un comando tuyo cuando pasa algo en la sesión (antes de una
herramienta, al terminar un turno, al arrancar). A diferencia de los comandos,
**no basta con dejar el archivo en una carpeta**: hay que registrarlo en un
`settings.json`. Los scripts viven en [hooks/](hooks/) y ahí está el bloque JSON
para pegar. Ver [hooks/README.md](hooks/README.md).

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
