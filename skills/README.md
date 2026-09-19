# skills/

Comandos que invocas con `/nombre`. Cada uno es un directorio con un `SKILL.md`
dentro, y el nombre del comando sale del **directorio**, no del frontmatter.

Se enganchan con una junction:

```powershell
New-Item -ItemType Junction -Path "$HOME\.claude\skills" -Target "<ruta-al-repo>\skills"
```

```bash
ln -s "<ruta-al-repo>/skills" ~/.claude/skills
```

> Este README no estorba: Claude Code solo reconoce `SKILL.md` dentro de un
> subdirectorio, asi que un archivo suelto en la raiz de `skills/` se ignora sin
> error.

## Catalogo

| Comando | Para que |
|---|---|
| [`/finalizar`](finalizar/SKILL.md) | Cierra la sesion de trabajo: registra la deuda en `deuda-tecnica.md`, commitea, mergea a la rama base, y reporta solo lo que requiere tu accion manual. |

## Que guardar aqui

Una skill se inyecta en **esta** conversacion y se queda en contexto. Ve todo lo
que tu ves y puede razonar con ello. Esa es la diferencia con un agente, que
arranca a ciegas.

### Va aqui

- **Procedimientos repetibles que tienen criterio.** Pasos que siempre son los
  mismos pero donde hay que decidir sobre la marcha: cerrar una sesion,
  preparar una release, migrar un modulo.
- **Flujos que quieres disparar tu**, por su nombre, cuando te convenga.
- **Conocimiento que Claude debe seguir al pie de la letra** cuando la tarea
  aparece, y que seria demasiado largo para el `CLAUDE.md`.

### No va aqui

- **Exploracion pesada que devuelve poco.** Barrer el repo, leer veinte
  archivos: eso gasta tu contexto. Es un **agente**, en `agents/`.
- **Lo que tiene que pasar siempre, sin excepcion.** Una skill se invoca; un
  **hook** se cumple. Si no puede fallar, va en `hooks/`.
- **Una instruccion de una linea.** Si cabe en el `CLAUDE.md`, va ahi: una skill
  que solo dice una cosa es una capa de mas.

### Skill, agente o hook

| Quieres... | Es un... |
|---|---|
| Un procedimiento que invocas con `/algo` en esta conversacion | skill, en `skills/` |
| Delegar trabajo pesado y recibir solo el resultado | agente, en `agents/` |
| Que algo pase solo al ocurrir un evento, sin pedirlo | hook, en `hooks/` |

### Reglas de oro

- **La `description` dice cuando usarlo**, no solo que hace. Es lo que Claude
  lee para decidir si la invoca sola.
- **`disable-model-invocation: true` en todo lo que tenga efectos
  secundarios** (commitear, mergear, empujar, desplegar). Que lo dispares tu, no
  el modelo por su cuenta.
- **Di explicitamente que NO reportar.** Sin eso, Claude resume de mas y la
  skill deja de ahorrarte tiempo.
- **Los bloques ` ```! ` abortan la invocacion entera si salen != 0.** Terminalos
  en `true` y protege cada linea. Es el error mas comun escribiendo comandos
  aqui.
- **`SKILL.md` corto.** Si crece, parte el detalle en archivos de apoyo dentro
  del mismo directorio y enlazalos: se cargan solo cuando hacen falta.

## El formato completo

El frontmatter campo por campo, los argumentos, la inyeccion de contexto con
`` !`cmd` ``, como probar los bloques `!` en los cuatro estados de repo, y el
checklist antes de commitear estan en [docs/comandos.md](../docs/comandos.md).
