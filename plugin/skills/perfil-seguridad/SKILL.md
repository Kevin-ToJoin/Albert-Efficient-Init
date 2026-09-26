---
name: perfil-seguridad
description: Principios de seguridad para autenticacion, datos de usuarios, endpoints publicos, pagos y secretos - secretos fuera del codigo, acceso cerrado por defecto, guards en el servidor, errores genericos al cliente. Cargarlo cuando el trabajo toque cualquiera de esos temas.
---

# Perfil de seguridad

Se aplica encima de las reglas base del `CLAUDE.md` de la raiz.

Para cuando el trabajo toca autenticacion, datos de usuarios, endpoints
publicos, pagos o secretos.

## Secretos

- Ningun secreto en el codigo. Ni de ejemplo, ni "temporal", ni en un comentario.
  Va a una variable de entorno y el codigo referencia la variable.
- `.env` gitignoreado siempre. Si hace falta versionar la forma del archivo, es
  un `.env.example` con las claves y sin los valores.
- Un secreto commiteado sigue en el historial aunque lo borres despues. Si
  ocurre, lo que toca es rotarlo, no solo quitarlo.
- Nunca imprimas un secreto en un log, en un error ni en una respuesta.

## Datos

- Cerrado por defecto. Una tabla, un bucket o una coleccion nace sin acceso
  publico y se abre solo lo que hace falta.
- Si los datos son por usuario, el filtro va **en la base** (row-level
  security o equivalente). Filtrar en el cliente no es seguridad: es
  presentacion.
- El cliente puede pedir cualquier cosa. Asume que la peticion viene modificada.

## Autenticacion y autorizacion

- El guard vive en el servidor. Ocultar un boton en el front no protege nada.
- Un token que llega del cliente se valida contra el emisor: firma, expiracion,
  audiencia. Decodificar un JWT no es validarlo.
- Autenticacion y autorizacion son dos cosas. Saber quien es no dice que puede
  hacer: comprueba las dos.

## Superficie expuesta

- Rate limit en login, registro, recuperacion de contrasena y en todo lo que
  cueste dinero o mande correo.
- Sin endpoints de debug, admin, metricas ni introspeccion de GraphQL abiertos
  en produccion.
- Sin `debug: true` ni modo verboso en la configuracion de produccion.

## Errores y logs

- Al cliente, mensaje generico y un identificador. El stack trace, la query y
  el nombre de la tabla van al log, nunca a la respuesta.
- Loguea los eventos que importan: login, fallo de auth, cambio de permisos,
  pago. Sin ellos no hay forma de reconstruir un incidente.
- No loguees contrasenas, tokens, tarjetas ni mas datos personales de los
  necesarios. Un log es otro sitio del que se pueden filtrar.

## Al revisar

- Di que esta y que falta, con `archivo:linea`. Sin niveles de severidad
  inventados.
- Distingue "no esta" de "no lo veo desde aqui". Que el repo no muestre las
  policies de la base no prueba que no existan.
