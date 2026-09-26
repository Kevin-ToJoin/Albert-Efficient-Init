# Reglas base, perfiles y CLAUDE.md

Las reglas llegan al repo destino en tres capas:

| Capa | Archivo | Como llega |
|---|---|---|
| Reglas base | `plugin/reglas-base.md` | Solas. Un hook las inyecta en cada sesion y cada subagente |
| Perfiles | `plugin/skills/perfil-*/SKILL.md` | Solos. Claude los carga cuando la tarea lo pide |
| Lo del proyecto | `CLAUDE.md` del repo destino | Lo escribe su equipo. `/albert:iniciar` crea el esqueleto |

## Por que las reglas base no van en el CLAUDE.md

Un plugin no puede aportar un `CLAUDE.md`: uno en la raiz del plugin no se
carga, y `claude plugin validate` lo marca. La version anterior lo resolvia
copiando las reglas al `CLAUDE.md` del repo destino, y eso tenia dos costos: un
paso mas para integrar el toolkit, y reglas congeladas en cada repo que nunca
recibian una mejora.

Ahora [`plugin/hooks/reglas-base.js`](../plugin/hooks/reglas-base.js) las
devuelve como `additionalContext` en dos eventos:

- **`SessionStart`**: al abrir, reanudar, limpiar o compactar una sesion.
- **`SubagentStart`**: al arrancar cada subagente, que no ve el contexto de la
  sesion principal. Cumple el papel que tenia el `CLAUDE.md`, que los subagentes
  si cargan.

Consecuencias:

- **Editar `reglas-base.md` cambia todos los repos integrados** con la siguiente
  actualizacion. Es la ventaja y es el riesgo: revisalo como un release.
- **No se ven en el repo destino.** Quien quiera saber que reglas recibe Claude
  las lee aqui. Para cambiarlas en un repo concreto, se escribe lo contrario en
  su `CLAUDE.md`: las propias reglas dicen que el `CLAUDE.md` del proyecto manda.
- **Tope de 10.000 caracteres**, el limite de `additionalContext`. Hoy ocupan
  unos 2.000, y `guards.test.js` falla si se pasan.

> **Ojo al editar `reglas-base.md`.** El `CLAUDE.md` de la raiz de este repo lo
> importa, asi que un cambio ahi tambien cambia como se comporta Claude Code
> trabajando *en este* repo. Una sola fuente.

## Los perfiles

Skills que Claude carga **solo cuando la tarea lo pide**, leyendo su
`description`. Se actualizan con el plugin como todo lo demas.

| Skill | Para que |
|---|---|
| `albert:perfil-codigo` | Desarrollo, code review, debugging, refactors |
| `albert:perfil-analisis` | Analisis de datos, research, reporting |
| `albert:perfil-seguridad` | Autenticacion, datos de usuarios, endpoints publicos, pagos, secretos |

Tambien se pueden pedir en un prompt: *"aplica el perfil de codigo y revisa
esta funcion"*.

### Agregar un perfil

1. Crea `plugin/skills/perfil-<nombre>/SKILL.md` con `name` y una
   `description` que diga **cuando** aplica: es lo unico que Claude lee para
   decidir si lo carga.
2. Sin `disable-model-invocation`: un perfil tiene que poder cargarlo Claude
   solo.
3. Agregalo a la seccion *Perfiles* de `reglas-base.md` y a la tabla de arriba.

## Que va en las reglas base y que no

Solo reglas que valen para **cualquier** proyecto: conducta, alcance,
prioridad. Lo especifico de un stack o de un tipo de tarea va en un perfil. Lo
especifico de un repo lo escribe su equipo en su `CLAUDE.md`.

Cada linea de `reglas-base.md` entra en el contexto de cada sesion y de cada
subagente de cada repo integrado. Se paga en todos lados.
