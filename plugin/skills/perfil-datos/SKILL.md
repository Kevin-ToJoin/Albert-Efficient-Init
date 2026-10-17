---
name: perfil-datos
description: Principios para bases de datos y migraciones - migraciones reversibles y por pasos, indices para lo que se consulta, transacciones, backups que se han restaurado de verdad, consultas sin N+1. Cargarlo cuando el trabajo toque esquemas, migraciones, consultas o el modelo de datos.
---

# Perfil de datos

Se aplica encima de las reglas base que inyecta el plugin albert. Los accesos y
las policies viven en `albert:perfil-seguridad`; aqui va la integridad y el
rendimiento.

## Migraciones

- Una migracion es un archivo versionado en el repo, nunca un cambio a mano en
  produccion. Si no esta en el repo, no existe.
- No edites una migracion que ya corrio en otro entorno. Agrega una nueva.
- Cambios destructivos en pasos separados: primero deja de usarse la columna,
  despues se despliega, despues se borra. Renombrar o borrar de golpe rompe a
  la version anterior del codigo mientras el despliegue aun no termina.
- Una columna `NOT NULL` nueva en una tabla con filas necesita un valor por
  defecto o un relleno previo. Si no, la migracion falla a medias.
- Antes de una migracion grande, di cuanto bloquea. Un `ALTER` sobre una tabla
  grande puede dejarla sin escrituras.

## Integridad

- Las reglas que no pueden fallar van en la base: `NOT NULL`, `UNIQUE`, claves
  foraneas, `CHECK`. Validar solo en la aplicacion deja pasar a cualquier otro
  cliente que escriba en la tabla.
- Lo que debe pasar junto va en una transaccion. Dos escrituras que dependen
  una de la otra sin transaccion dejan estados a medias.
- El dinero no se guarda en `float`. Entero en la unidad minima, o `numeric`.
- Las fechas se guardan en UTC y con zona. La conversion es cosa de la capa de
  presentacion.

## Rendimiento

- Cada columna por la que se filtra, se une o se ordena con frecuencia necesita
  indice. Un indice que nadie usa tambien cuesta en cada escritura.
- Un bucle que lanza una consulta por fila es un N+1. Se resuelve con un join o
  con una sola consulta de `IN`.
- Sin `SELECT *` en codigo de produccion: trae columnas que no necesitas y
  rompe cuando el esquema cambia.
- Toda lista que crece va paginada. Una consulta sin `LIMIT` sobre una tabla
  que crece es una bomba con retardo.
- Mide con el plan de ejecucion (`EXPLAIN`) antes de decir que algo es lento.

## Backups

- Un backup que nunca se ha restaurado no es un backup. Si nadie lo probo, dilo
  como hueco.
- Di cada cuanto se hace, cuanto se conserva y cuanto tardaria la
  restauracion. Esos tres datos son el plan.

## Al revisar

- Di que esta y que falta, con `archivo:linea`.
- Distingue "no esta" de "no lo veo desde aqui": los indices y los backups
  pueden vivir en la base o en el proveedor y no en el repo.
