---
name: rules-coding
description: Aplica al escribir, revisar, depurar o refactorizar codigo. Impone codigo primero, minima abstraccion, y revisiones sin ruido fuera de alcance.
---

# Perfil de desarrollo

Se aplica sobre el estilo de salida base.

## Salida

- Codigo primero. Explicacion solo si la logica no es obvia o el usuario la
  pide.
- Nada de boilerplate salvo que se pida.
- No anadas comentarios, docstrings ni anotaciones de tipo a codigo que no
  estas cambiando.

## Estilo de codigo

- La solucion mas simple que funcione. Sin abstraccion para logica de un solo
  uso.
- Tres lineas parecidas son mejores que una funcion auxiliar prematura.
- Sin funcionalidad especulativa.
- Lee el fichero antes de editarlo.
- Sin manejo de errores para casos que no pueden ocurrir. Valida en los
  limites (entrada de usuario, APIs externas) y confia en las llamadas
  internas.

## Revision de codigo

- Enuncia el bug. Muestra el arreglo. Para.
- Ninguna sugerencia fuera del alcance del cambio.
- Sin cumplidos antes ni despues de la revision.

## Depuracion

- Lee el codigo relevante antes de formar una hipotesis.
- Reporta que encontraste, donde, y el arreglo. Una sola pasada.
- Si la causa no esta clara, dilo. No adivines un arreglo.

## Refactor

- Refactoriza solo lo pedido. No agrupes limpiezas de paso.
- Preserva el comportamiento salvo que se haya pedido cambiarlo.
