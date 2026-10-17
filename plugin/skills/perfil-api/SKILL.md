---
name: perfil-api
description: Principios para backend y diseno de APIs - validacion en el borde, codigos de estado correctos, idempotencia en lo que se puede reintentar, paginacion, timeouts, cambios que no rompen a los clientes. Cargarlo cuando el trabajo toque endpoints, servicios, integraciones con terceros o colas.
---

# Perfil de API y backend

Se aplica encima de las reglas base que inyecta el plugin albert. Auth, rate
limit y errores hacia el cliente estan en `albert:perfil-seguridad`.

## Contrato

- Valida la entrada en el borde: tipo, rango, longitud y formato. Rechaza lo que
  no encaja con un 4xx claro; no lo "arregles" en silencio.
- Los codigos de estado significan algo: 400 entrada invalida, 401 sin
  identidad, 403 sin permiso, 404 no existe, 409 conflicto, 429 limite. Un 200
  con un error dentro del cuerpo rompe a todo cliente que mire el codigo.
- Una respuesta de error tiene siempre la misma forma.
- Cambiar un campo que ya se usa es un cambio de contrato. Agregar campos es
  seguro; quitar, renombrar o cambiar un tipo rompe a los clientes. Eso va con
  version nueva o con un periodo en que conviven los dos.

## Reintentos

- Todo lo que pueda reintentarse (un cliente que pierde la respuesta, una cola
  que reentrega) tiene que ser idempotente. Un cobro o un correo se protege con
  una clave de idempotencia, no con la esperanza de que no se repita.
- Reintenta solo lo que es seguro reintentar, con espera creciente y un tope.
  Reintentar sin limite contra un servicio caido lo tumba mas.

## Llamadas a terceros

- Toda llamada externa lleva timeout. Sin timeout, un tercero lento deja colgado
  a todo tu servicio.
- Asume que el tercero falla. Decide que hace tu endpoint cuando no responde:
  error limpio, valor en cache o degradar. No lo dejes sin decidir.
- Los webhooks que recibes se verifican (firma) y se procesan de forma
  idempotente.

## Listas y carga

- Toda coleccion se pagina, con un maximo que el cliente no puede subir.
- Lo lento (correo, informes, procesos largos) va a una cola, no dentro de la
  peticion HTTP.
- Sin trabajo en cada peticion que podria hacerse una vez al arrancar.

## Configuracion

- Lo que cambia entre entornos viene del entorno, no del codigo.
- Falla al arrancar si falta una variable obligatoria, en lugar de fallar en la
  primera peticion que la use.

## Al revisar

- Di que esta y que falta, con `archivo:linea`.
- Si la API tiene clientes que no ves (apps moviles, terceros), di que un cambio
  de contrato puede romperlos aunque aqui todo compile.
