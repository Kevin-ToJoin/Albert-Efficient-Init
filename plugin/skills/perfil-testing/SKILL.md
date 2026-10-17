---
name: perfil-testing
description: Escribir, revisar o arreglar tests y pruebas unitarias, de integracion o end-to-end - que casos cubrir, bordes, mocks, cobertura, tests intermitentes o que pasan siempre. Cargarlo siempre que la tarea mencione tests, pruebas, casos de prueba o cobertura.
---

# Perfil de testing

Se aplica encima de las reglas base que inyecta el plugin albert.

## Que probar

- Prueba el comportamiento observable, no la implementacion. Un test acoplado a
  como esta escrito el codigo se rompe en cada refactor sin haber encontrado un
  solo bug.
- Prioriza lo que cuesta caro si falla: dinero, permisos, perdida de datos,
  migraciones. Cubrir todo por igual no es mejor que cubrir bien lo critico.
- Los bordes dan mas bugs que el caso feliz: vacio, nulo, cero, uno, el maximo,
  duplicados, caracteres raros, fechas limite.
- Cada bug que se arregla deja un test que habria fallado antes del arreglo.

## Que un test sea bueno

- Falla por la razon correcta. Antes de fiarte de un test nuevo, comprueba que
  falla cuando rompes a proposito lo que prueba.
- Un test que no puede fallar (sin aserciones, o que asierta lo que acaba de
  construir) es peor que no tener ninguno: da confianza falsa.
- Un test, una razon para fallar. Si el nombre necesita "y", son dos tests.
- El nombre dice la situacion y lo esperado. Cuando falla en CI, el nombre es lo
  unico que se lee.
- Independiente del orden y del resto: cada test prepara lo que necesita y no
  deja basura.

## Dobles y datos

- Simula solo lo que no controlas: red, reloj, servicios de terceros. Simular tu
  propio codigo hace que el test pruebe el simulacro.
- Si todo esta simulado, nada esta probado. Deja al menos una prueba que cruce
  las capas de verdad, con la base real o una equivalente.
- El tiempo y el azar entran por parametro, no se leen dentro. Si no, el test es
  intermitente.
- Los datos de prueba son minimos y se ven en el propio test. Un archivo de
  datos enorme que nadie entiende no documenta nada.

## Tests que ya existen

- Un test saltado (`skip`, `xfail`, `.only`) sin motivo escrito es deuda. Anotalo
  en `deuda-tecnica.md` o arreglalo.
- Si un test falla, no cambies la asercion para que pase hasta entender si el
  que esta mal es el test o el codigo.
- Un test intermitente se arregla o se retira; no se reintenta hasta que pase.

## Al revisar

- Di que falta cubrir y por que importa, con `archivo:linea`.
- Si no corriste los tests, dilo. "Deberia pasar" no es "pase".
