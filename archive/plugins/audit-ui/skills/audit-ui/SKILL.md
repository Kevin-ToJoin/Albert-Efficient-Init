---
name: audit-ui
description: Recorre la interfaz de la aplicacion con un navegador real y audita flujos y accesibilidad.
disable-model-invocation: true
---

# Auditoria de interfaz

URL objetivo: `$ARGUMENTS`. Si esta vacio, usa `${user_config.base_url}`.

Requiere el MCP de Playwright, que este plugin declara. Si las herramientas del
navegador no estan disponibles, dilo y para: no describas lo que harias, no
simules una auditoria que no ocurrio.

## Antes de empezar

Comprueba que la URL responde. Si no responde, dilo y para: probablemente la
app no esta levantada, y ese es el hallazgo.

## Como proceder

Lanza los dos agentes:

1. `ui-tester` recorre los flujos principales.
2. `a11y-auditor` audita accesibilidad sobre las mismas pantallas.

## Informe

Una tabla, con evidencia real de la sesion de navegador:

| Severidad | Hallazgo | Pantalla | Como reproducirlo |
|---|---|---|---|

Cada hallazgo lleva los pasos exactos para reproducirlo. Un hallazgo que no se
puede reproducir no se reporta.
