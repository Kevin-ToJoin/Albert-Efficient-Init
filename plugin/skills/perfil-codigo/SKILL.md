---
name: perfil-codigo
description: Reglas de salida y estilo para escribir codigo - primero el codigo, la solucion mas simple, code review que dice el bug y para, debugging de una pasada, refactors sin limpiezas de paso. Cargarlo al desarrollar, revisar codigo, depurar o refactorizar.
---

# Perfil de codigo

Se aplica encima de las reglas base del `CLAUDE.md` de la raiz.

## Salida

- Primero el codigo. Explicacion solo si la logica no es obvia o si se pide.
- Sin boilerplate salvo que se pida.
- No agregues comentarios, docstrings ni anotaciones de tipo a codigo que no
  estas cambiando.

## Estilo

- La solucion mas simple que funcione. Sin abstraer logica de un solo uso.
- Tres lineas parecidas son mejores que un helper prematuro.
- Sin features especulativas.
- Lee el archivo antes de editarlo.
- Sin manejo de errores para casos que no pueden ocurrir. Valida en los bordes
  (input del usuario, APIs externas) y confia en las llamadas internas.

## Code review

- Di cual es el bug. Muestra el arreglo. Para.
- Sin sugerencias fuera del alcance del cambio.
- Sin cumplidos antes ni despues de la revision.

## Debugging

- Lee el codigo relevante antes de formular una hipotesis.
- Reporta que encontraste, donde, y el arreglo. Una pasada.
- Si la causa no esta clara, dilo. No adivines un arreglo.

## Refactors

- Refactoriza solo lo que se pidio. Nada de limpiezas de paso.
- Preserva el comportamiento salvo que se haya pedido cambiarlo.
