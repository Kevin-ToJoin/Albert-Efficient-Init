# Triaje de Proyectos

Un manual de campo para entrar en un proyecto que no conoces. Se navega por
dos ejes y tiene buscador.

**Publicado:** https://claude.ai/code/artifact/a33fca32-5b41-4f7f-a71b-01bc2ae7abda

## La idea

Empiezas por el estado en el que está el proyecto, no por la tecnología que
usa. El orden de trabajo cambia mucho más entre un proyecto vivo y uno
abandonado que entre Node y Python.

Cuatro situaciones, con el criterio explícito para reconocer cada una:

| | Cómo saber que estás aquí |
|---|---|
| Empiezo de cero | Menos de 30 commits, o menos de 90 días, sin tags de release |
| Está vivo y en marcha | Commit en los últimos 30 días, dos o más autores, CI presente |
| En mantenimiento | Último commit entre 30 días y 12 meses, y lo reciente son fixes |
| Heredé algo abandonado | Sin commits en 12 meses; o sin tests y sin CI con más de 500 ficheros |

Cada situación trae el riesgo real, el orden de trabajo, y **qué no tocar
todavía**, que suele ser la parte más útil.

## Las fichas

22 fichas repartidas en seis dominios, cada una empezando en hoja nueva: seguridad, calidad y tests, frontend,
backend, proceso y entrega, y trabajar con Claude. Se llega a ellas desde
cualquiera de los dos ejes o desde el buscador.

Cada ficha tiene la misma forma:

- **Qué es**, en dos líneas.
- **Cómo comprobarlo**, con pasos concretos.
- **Señal de alarma**: cómo suena una mala respuesta a esa comprobación.
- **Pídeselo así**: el prompt que devuelve algo accionable.
- **Para leer**: los recursos que merecen el tiempo.

Los enlaces apuntan a la entrada canónica de cada recurso y no a páginas
concretas. Las rutas profundas se rompen; las raíces no.

## Estructura del repo

```
book/triaje.html      # el libro completo, una sola página sin dependencias
archive/              # trabajo previo, no mantenido

```

Para actualizarlo: edita `book/triaje.html` y republica sobre la misma URL.

## Archivo

`archive/` guarda dos iteraciones anteriores del proyecto: un instalador que
copiaba reglas dentro del repo destino, y después un marketplace de plugins de
Claude Code. El contenido de aquellas skills y agentes es la materia prima de
las fichas de este libro.

Si ejecutaste el instalador original en algún proyecto, límpialo con
`bash archive/legacy/uninstall.sh /ruta/al/proyecto`.

## Attribution

Parte de las ideas vienen de
[drona23/claude-token-efficient](https://github.com/drona23/claude-token-efficient)
(MIT). Ver [ATTRIBUTION.md](ATTRIBUTION.md).

## License

MIT. Ver [LICENSE](LICENSE).
