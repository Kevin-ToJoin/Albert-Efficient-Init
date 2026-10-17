---
name: perfil-frontend
description: Principios para interfaces web - accesibilidad basica, los cuatro estados de cada pantalla (carga, vacio, error, exito), rendimiento percibido, formularios, y no confiar en el cliente. Cargarlo cuando el trabajo toque componentes, paginas, formularios o estado del navegador.
---

# Perfil de frontend

Se aplica encima de las reglas base que inyecta el plugin albert. Lo que el
front oculta no esta protegido: ver `albert:perfil-seguridad`.

## Estados

- Toda pantalla que pide datos tiene cuatro estados: cargando, vacio, error y
  con datos. Si solo se disenio el ultimo, los otros tres se ven rotos.
- Un error le dice al usuario que hacer (reintentar, volver, contactar). "Algo
  salio mal" solo no basta.
- Un boton que dispara una accion se desactiva mientras corre. Si no, el doble
  clic duplica la accion.

## Accesibilidad

- Usa el elemento correcto: `button` para acciones, `a` para navegar, `label`
  para cada campo. Un `div` con un manejador de clic no se alcanza con teclado.
- Todo lo que se puede hacer con el raton se puede hacer con teclado, y el foco
  se ve.
- Las imagenes con contenido llevan `alt`; las decorativas, `alt=""`.
- El color no es la unica forma de decir algo. Revisa el contraste del texto.
- Un error de formulario se asocia al campo y se anuncia, no solo se pinta de
  rojo.

## Formularios

- Valida en el cliente por comodidad y en el servidor por seguridad. La del
  cliente nunca sustituye a la otra.
- Conserva lo que el usuario escribio cuando el envio falla.
- Un formulario largo que se pierde al recargar es una queja segura.

## Rendimiento

- Lo que se ve primero se carga primero. Difiere el resto.
- Imagenes con dimensiones declaradas, para que la pagina no salte al cargarlas.
- Una dependencia nueva se paga en el tamano del paquete de todos los usuarios.
  Antes de agregarla, mira cuanto pesa y si ya tienes algo que lo resuelve.
- Una lista larga se virtualiza o se pagina; no se pinta entera.
- Mide antes de optimizar. No memorices por reflejo.

## Estado

- Cada dato tiene un solo dueno. Copiar el mismo dato en dos sitios acaba en que
  se desincronizan.
- Lo que se puede derivar de otro estado se calcula; no se guarda aparte.
- Sin secretos en el codigo del cliente: todo lo que llega al navegador lo ve
  cualquiera.

## Al revisar

- Di que esta y que falta, con `archivo:linea`.
- Lo visual y lo de teclado no se verifican leyendo codigo. Dilo si no lo
  abriste en un navegador.
