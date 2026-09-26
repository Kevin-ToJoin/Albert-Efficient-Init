# CLAUDE.md y perfiles

El toolkit reparte las reglas en dos piezas:

```
plugin/skills/iniciar/CLAUDE-plantilla.md   ->  <repo destino>/CLAUDE.md   (lo escribe /albert:iniciar)
plugin/skills/perfil-*/SKILL.md             ->  llegan solos con el plugin
```

## Por que el CLAUDE.md no llega solo

Un plugin no puede aportar un `CLAUDE.md`: uno en la raiz del plugin no se
carga, y `claude plugin validate` lo marca. Por eso la plantilla vive dentro de
la skill `iniciar`, que la escribe en el repo destino, donde se commitea y
aplica a todo el equipo.

Consecuencia: **editar la plantilla no cambia los repos ya integrados**. Les
llega la version nueva la proxima vez que alguien corra `/albert:iniciar`, y
aun asi no pisa unas reglas base que difieran: avisa y deja decidir. Es a
proposito, porque cada equipo puede haber ajustado las suyas.

> **Ojo al editar la plantilla.** El `CLAUDE.md` de la raiz de este repo la
> importa, asi que un cambio ahi tambien cambia como se comporta Claude Code
> trabajando *en este* repo. Una sola fuente. La plantilla tiene que seguir
> siendo **autocontenida**, porque en el repo destino va sola y ahi no hay nada
> que importar.

## Los perfiles

Antes eran archivos sueltos que habia que copiar. Ahora son skills del plugin,
y eso resuelve dos cosas a la vez:

- **Se cargan solo cuando la tarea lo pide.** Claude lee la `description` de
  cada skill y la carga si aplica, que es exactamente lo que hacia la seccion
  de perfiles del `CLAUDE.md`, pero sin depender de que Claude lea un archivo.
- **Se actualizan con el plugin.** Un cambio en un perfil llega a todos los
  repos con el siguiente push, sin volver a copiar nada.

| Skill | Para que |
|---|---|
| `albert:perfil-codigo` | Desarrollo, code review, debugging, refactors |
| `albert:perfil-analisis` | Analisis de datos, research, reporting |
| `albert:perfil-seguridad` | Autenticacion, datos de usuarios, endpoints publicos, pagos, secretos |

Tambien se pueden pedir en un prompt: *"aplica el perfil de codigo y revisa
esta funcion"*.

## Agregar un perfil

1. Crea `plugin/skills/perfil-<nombre>/SKILL.md` con `name` y una
   `description` que diga **cuando** aplica: es lo unico que Claude lee para
   decidir si lo carga.
2. Sin `disable-model-invocation`: un perfil tiene que poder cargarlo Claude
   solo.
3. Agregalo a la lista de la seccion *Perfiles* de `CLAUDE-plantilla.md` y a la
   tabla de arriba.

## Que va en la plantilla y que no

Solo reglas que valen para **cualquier** proyecto: conducta, alcance,
prioridad. Lo especifico de un stack o de un tipo de tarea va en un perfil. Lo
especifico de un repo lo agrega su equipo debajo de las reglas base, en su
propio `CLAUDE.md`.

La plantilla entra en el contexto de cada sesion y de cada subagente de cada
repo destino. Cada linea que se le agrega se paga en todos lados.
