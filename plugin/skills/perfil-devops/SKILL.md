---
name: perfil-devops
description: Principios para CI/CD, despliegues y operacion - pipeline que bloquea, despliegues reversibles, entornos que se parecen, alertas sobre sintomas, y que hacer cuando algo se rompe en produccion. Cargarlo cuando el trabajo toque pipelines, infraestructura, despliegues, monitoreo o incidentes.
---

# Perfil de DevOps y operacion

Se aplica encima de las reglas base que inyecta el plugin albert. Secretos y
accesos estan en `albert:perfil-seguridad`.

## CI

- El pipeline corre en cada PR y **bloquea el merge** si falla. Un CI que se
  ignora no protege nada.
- Lo que corre en CI tiene que poder correr igual en local, con un comando.
- Un test intermitente se arregla o se retira. Dejarlo ensena a ignorar el rojo.
- Fija las versiones de lo que usa el pipeline (acciones, imagenes, runtime). Un
  `latest` cambia bajo tus pies.

## Despliegue

- Todo despliegue tiene marcha atras. Antes de lanzar, di como se vuelve a la
  version anterior y cuanto tarda.
- Las migraciones de base de datos van compatibles hacia atras, para poder
  volver el codigo sin volver la base. Ver `albert:perfil-datos`.
- Cambios arriesgados detras de una bandera (feature flag): se despliega
  apagado y se enciende aparte. Desplegar y lanzar son dos decisiones.
- Sin despliegues manuales a produccion que no queden registrados. Lo que
  alguien hizo "a mano un momento" es lo que nadie puede reproducir despues.
- No despliegues un viernes por la tarde nada que no puedas revertir en minutos.

## Entornos

- Staging se parece a produccion, o sus resultados no valen. Di en que difieren.
- La configuracion de cada entorno vive fuera del codigo y se puede reconstruir.
- La infraestructura se describe en el repo (IaC), no en clics de una consola.

## Observabilidad

- Alerta sobre lo que el usuario siente (errores, latencia, caida), no sobre
  cada metrica interna. Una alerta que salta cada dia se silencia.
- Cada alerta dice que hacer. Una alerta sin accion es ruido.
- Los logs llevan un identificador de peticion, para seguir una operacion entera.
- Un servicio sin health check no se puede orquestar ni vigilar.

## Incidentes

- Primero detener el dano (revertir, apagar la bandera) y despues buscar la
  causa. Depurar en vivo con el sistema roto alarga la caida.
- Despues del incidente, un postmortem sin culpables: que paso, por que no se
  vio antes, y que cambia para que no se repita. Lo que no se escribe se repite.

## Costos

- Todo recurso en la nube tiene dueno y una razon. Lo que nadie reclama, se
  apaga.
- Pon alertas de gasto antes del primer despliegue, no despues de la primera
  factura.

## Al revisar

- Di que esta y que falta, con `archivo:linea`.
- Distingue "no esta" de "no lo veo desde aqui": la proteccion de ramas, las
  alertas y los permisos viven en el proveedor y no en el repo.
