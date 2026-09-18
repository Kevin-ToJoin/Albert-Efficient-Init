# Albert-Efficient-Init

Toolkit personal de comandos, hooks y reglas para Claude Code. El repo es
**contenido puro**: no hay instalador, ni build, ni suite de tests. Todo lo que
hay son archivos Markdown que Claude Code carga desde otro sitio.

La documentacion de este repo esta en espanol. Mantenla asi.

## Reglas base

Las que este repo distribuye a otros proyectos, aplicadas aqui tambien:

@rules/CLAUDE-root-template.md

Con una correccion de ruta: aqui los perfiles viven en `rules/Efficiency/`, no
en `Efficiency/`.

## Tres carpetas, tres mecanicas distintas

Es lo que mas se presta a error en este repo. Cada una llega a Claude Code por
una via diferente:

| Carpeta | Como llega | Implicacion |
|---|---|---|
| `skills/` | Junction: `~/.claude/skills` apunta aqui | Editar un `SKILL.md` cambia el comando **en vivo y en todos los repos** del usuario |
| `hooks/` | No llega sola | Necesita una entrada en `settings.json`. No existe carpeta auto-cargable |
| `rules/` | No llega sola | Se copia a mano al proyecto que la quiera |

## Lo que no es obvio

- **No reintroduzcas un instalador.** Habia cinco scripts, un marketplace y un
  plugin; se borraron a proposito y se cambiaron por la junction. El motivo
  esta en la bitacora de `deuda-tecnica.md`. Actualizar es `git pull`.
- **Un comando es un directorio con `SKILL.md`**, no un `.md` suelto. El nombre
  del comando sale del directorio, no del campo `name` del frontmatter.
- **Los bloques ` ```! ` abortan el comando entero si salen != 0.** Se ejecutan
  antes de que Claude vea la skill. Termina siempre en `true` y protege cada
  linea con `||`. Pruebalos en cuatro estados: repo normal, repo sin `main` ni
  `master`, directorio que no es git, y repo sin ningun commit. El metodo esta
  en `docs/comandos.md`.
- **`rules/CLAUDE-root-template.md` se llama asi a proposito.** Si se llamara
  `CLAUDE.md`, Claude Code lo auto-cargaria al trabajar dentro de `rules/`. No
  lo renombres.
- **Los hooks tienen una alternativa file-drop**: declararlos en el frontmatter
  de una skill. Esos si viajan con un `git pull` y no tocan ningun
  `settings.json`.

## Al terminar

`deuda-tecnica.md` lo mantiene el comando `/finalizar`. Lo que quede a medias,
sin verificar o decidido a medias va ahi, con `[M]` si requiere accion manual
del usuario o `[A]` si un agente puede cerrarlo solo. No lo reportes en el chat
si ya quedo escrito en el archivo.
