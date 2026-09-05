---
name: audit-quality
description: Auditoria de mantenibilidad: codigo muerto, huecos de cobertura en rutas criticas y salud de dependencias.
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git log *) Bash(git ls-files *) Bash(find *) Bash(wc *)
---

# Auditoria de calidad

Alcance: `$ARGUMENTS` si se indica algo; si no, el repositorio completo.

Esto no duplica `/code-review` ni `/simplify`, que ya vienen de serie y operan
sobre el diff. Esto mira el repositorio en reposo: lo que sobra, lo que no esta
cubierto y lo que se esta pudriendo.

## Como proceder

Lanza los tres agentes en paralelo:

1. `dead-code` sobre exportaciones y ficheros huerfanos.
2. `test-coverage` sobre las rutas criticas sin test.
3. `dependency-health` sobre manifiestos y su antiguedad.

## Informe

Ordena por **coste de no arreglarlo**, no por facilidad de arreglo. Una tabla:

| Impacto | Hallazgo | Ubicacion | Coste de ignorarlo |
|---|---|---|---|

Cierra con una unica recomendacion: que tocarias primero y por que. Una sola,
no una lista de deseos.

No propongas refactors amplios. Este informe describe el estado, no reescribe
el proyecto.
