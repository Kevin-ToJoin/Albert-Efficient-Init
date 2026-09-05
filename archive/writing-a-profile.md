# Anadir una skill o un agente

## Donde va cada cosa

```
plugins/<plugin>/
├── .claude-plugin/plugin.json
├── skills/<nombre>/SKILL.md      # lo que invocas con /<nombre>
├── agents/<nombre>.md            # subagentes que la skill despacha
├── output-styles/<nombre>.md     # estilo de respuesta global
└── .mcp.json                     # servidores MCP del plugin
```

Los componentes en estas rutas se descubren solos. No hace falta declararlos en
`plugin.json` salvo que uses rutas distintas.

Si creas un plugin nuevo, anadelo ademas al array `plugins` de
`.claude-plugin/marketplace.json` con su `name` y su `source` relativo.

## Skill

```yaml
---
name: mi-skill
description: Cuando debe usarse. Esto es lo que decide si Claude la invoca sola.
disable-model-invocation: true    # solo se invoca escribiendo /mi-skill
context: fork                     # corre en un subagente aislado
agent: general-purpose            # Explore para solo lectura
background: false                 # espera el resultado
allowed-tools: Read Grep Glob Bash(git log *)
---
```

Decide dos cosas antes de escribir el cuerpo:

- **Quien la invoca.** Si es pesada, `disable-model-invocation: true`. Su
  `description` deja de competir por contexto y solo carga cuando la pides.
- **Donde corre.** Si produce un informe largo, `context: fork`. El ruido se
  queda en el subagente.

### Inyeccion de contexto

Un bloque marcado con `!` se ejecuta **antes** de que Claude lea la skill, y su
salida sustituye al bloque:

````
```!
git log --oneline -20 2>/dev/null || true
```
````

Vale mucho mas que pedirle a Claude que vaya a buscar el dato, porque llega ya
resuelto.

**Cuidado**: si el comando falla, se aborta la invocacion entera de la skill.
Termina siempre en `|| true` y silencia stderr. Un `cat` de un fichero que no
existe basta para tumbarla.

## Agente

```yaml
---
name: mi-agente
description: En que se especializa.
model: sonnet          # opus para razonamiento dificil
effort: medium
tools: [Read, Grep, Glob, Bash]
---
```

Un agente sin `Write` ni `Edit` no puede romper nada. Para auditorias es lo que
quieres.

## Lo que hace bueno a un agente de auditoria

Lo que distingue un informe util de uno que nadie lee no es la lista de cosas a
buscar, es lo que le dices sobre **cuando callarse**:

- Que haga cuando la herramienta que necesita no esta instalada. Debe decirlo y
  caer a revision manual, nunca inventar la salida.
- Como distinguir un hallazgo confirmado de una sospecha, y la obligacion de
  etiquetar la diferencia.
- Que falsos positivos son habituales en su dominio y como descartarlos antes
  de reportar.
- Permiso explicito para no encontrar nada. Sin eso, un agente rellena.

Los agentes de `audit-security/` y `audit-quality/` sirven de plantilla.

## Probarlo

```bash
claude plugin validate ./plugins/<plugin> --strict
claude plugin marketplace add ./
```
