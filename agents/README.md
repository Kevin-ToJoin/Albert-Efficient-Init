# agents/

Subagentes: tareas que corren en **su propia ventana de contexto** y devuelven
solo el resultado. Sirven para que la exploracion pesada (barrer el repo,
buscar en la web, leer veinte archivos) no te ensucie el contexto principal.

Se enganchan igual que las skills, con una junction:

```powershell
New-Item -ItemType Junction -Path "$HOME\.claude\agents" -Target "<ruta-al-repo>\agents"
```

```bash
ln -s "<ruta-al-repo>/agents" ~/.claude/agents
```

> Este README no estorba dentro de la carpeta: Claude Code ignora sin error los
> archivos que no llevan `name` en el frontmatter y los trata como
> documentacion.

## Catalogo

| Agente | Para que |
|---|---|
| [`auditor-deuda`](auditor-deuda.md) | Barre el repo y reporta la deuda tecnica que **no** esta en `deuda-tecnica.md`. Complementa a `/finalizar`, que solo mira la sesion actual. |

## Como se invoca

| Forma | Efecto |
|---|---|
| "usa el auditor-deuda para revisar esto" | Claude decide si delega |
| `@agent-auditor-deuda` | Garantiza que corra ese agente |
| `claude --agent auditor-deuda` | Lo pone como agente principal de la sesion |
| Solo por la `description` | Claude delega solo si la tarea encaja |

## Formato

```markdown
---
name: mi-agente
description: Que hace y cuando delegarle. Claude lee esto para decidir.
tools: Read, Grep, Glob, Bash
model: sonnet
color: blue
---

Aqui va el system prompt del agente: quien es, que procedimiento sigue y en
que formato reporta.
```

### Frontmatter

| Campo | Para que |
|---|---|
| `name` | **Obligatorio.** Minusculas y guiones. Sin `:`, que esta reservado. |
| `description` | **Obligatorio.** Cuando delegarle. Si pones "usar proactivamente", Claude delega mas. |
| `tools` | Lista blanca. Si lo omites hereda todas. Quitar `Write`/`Edit` es la forma de garantizar que un agente solo lea. |
| `disallowedTools` | Lista negra sobre lo heredado. |
| `model` | `sonnet`, `opus`, `haiku`, `fable`, un ID completo, o `inherit`. |
| `effort` | `low`, `medium`, `high`, `xhigh`, `max`. |
| `memory` | `user`, `project` o `local`. Memoria que sobrevive entre conversaciones. |
| `skills` | Precarga skills por nombre. Ojo: entra la skill **entera** en contexto. |
| `omitClaudeMd` | `true` para que **no** cargue los `CLAUDE.md`. |
| `permissionMode` | `default`, `acceptEdits`, `plan`, `bypassPermissions`... |
| `maxTurns` | Tope de turnos antes de parar. |
| `isolation` | `worktree` para correr en un worktree de git aislado. |
| `hooks` | Hooks con el alcance de este agente. |
| `color` | `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan`. |

## Lo que no es obvio

- **`/agents` ya no abre el asistente** de creacion desde la v2.1.198. Solo
  imprime un recordatorio. Los agentes se crean escribiendo el archivo, o
  pidiendoselo a Claude.
- **Un subagente no ve la conversacion.** No hereda el historial, ni los
  archivos que Claude ya leyo, ni las skills ya invocadas. Todo lo que necesite
  saber tiene que estar en su prompt o en el mensaje de delegacion.
- **Si carga los `CLAUDE.md`**, toda la jerarquia, salvo que pongas
  `omitClaudeMd: true`. Por eso importa mantenerlos cortos: entran en el
  contexto de cada subagente.
- **Nada de bloques ` ```! `.** La inyeccion de contexto con `!` es de las
  skills. El cuerpo de un agente es su system prompt y no ejecuta nada. Si
  necesita estado del repo, que lo consiga el mismo con `Bash`.
- **Los agentes en background tienen menos herramientas** que los de
  foreground. Si uno necesita algo raro, tenlo en cuenta.
- **El nombre tiene que ser unico en todo el arbol**, subcarpetas incluidas. La
  ruta no da namespace: la identidad sale solo del campo `name`.

## Antes de commitear un agente

- [ ] La `description` dice **cuando** delegarle, no solo que hace.
- [ ] `tools` recortado a lo minimo. Sin `Write`/`Edit` si solo debe reportar.
- [ ] Dice explicitamente que **no** reportar, o el agente se vuelve ruido.
- [ ] Dice que responder cuando no encuentra nada, en una linea.
- [ ] `claude plugin validate .claude/agents` pasa (v2.1.233+).
