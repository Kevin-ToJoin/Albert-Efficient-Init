# mcp/

MCP conecta Claude Code con sistemas de fuera: tu gestor de issues, una base de
datos, tus documentos, una API interna. Cada servidor aporta herramientas que
Claude puede llamar como llama a `Read` o `Bash`.

> **Esta carpeta no se engancha con junction, a diferencia de `skills/` y
> `agents/`.** La configuracion de MCP no es una carpeta que Claude Code lea:
> son entradas JSON en sitios concretos. Asi que aqui hay plantillas que
> **copias**, igual que en `rules/`.

## Donde vive de verdad la configuracion

| Alcance | Archivo | Para que |
|---|---|---|
| **Proyecto** | `.mcp.json` en la raiz del repo | Se commitea. Todo el equipo hereda los mismos servidores |
| **Usuario** | `~/.claude.json` | Tuyo, en todos tus proyectos |
| **Local** | `~/.claude.json`, bajo `projects["<ruta>"].mcpServers` | Tuyo y solo en ese proyecto. Es el alcance por defecto |

La forma comoda de escribirlos es el CLI, que edita el archivo correcto solo:

```bash
claude mcp add --transport http notion https://mcp.notion.com/mcp
claude mcp add --scope project --transport http mi-api https://api.interna/mcp
claude mcp add --transport stdio airtable -- npx -y airtable-mcp-server
claude mcp list
```

Ojo con `--scope`: si no lo pones, es `local`, o sea solo para ti y solo en ese
proyecto.

## Plantilla

[`mcp.json.ejemplo`](mcp.json.ejemplo) tiene las cuatro formas de transporte
listas para copiar. Para usarlo en un proyecto, copia lo que necesites a un
`.mcp.json` en la raiz de ese repo.

## Que guardar aqui

### Va aqui

- **Sistemas externos que consultas seguido** y que hoy resuelves copiando y
  pegando a mano: issues, documentos, tableros, una base de datos de solo
  lectura.
- **APIs internas de tu equipo**, en alcance `project`, para que todos tengan
  las mismas herramientas sin configurar nada.

### No va aqui

- **Lo que un comando local ya resuelve.** Si `git` o un script lo hacen, no
  metas un servidor: es una dependencia mas que puede caerse.
- **Servidores que no has revisado.** Corren con tus credenciales y ven lo que
  les des. Un servidor MCP es codigo de terceros con acceso.
- **Todo lo que "podria servir".** Cada servidor mete sus herramientas en el
  contexto de cada sesion. Tres servidores utiles funcionan mejor que doce.

### Reglas de oro

- **Nunca escribas un secreto en el JSON.** Usa `${VAR}` o `${VAR:-default}`,
  que se expanden desde el entorno.
- **Cuidado con el anti-fuga:** en servidores remotos, las variables cuyo nombre
  contiene `TOKEN`, `SECRET`, `PASSWORD`, `KEY` o `AUTH` **no se expanden** en
  `url` ni en `headers`, a proposito, para que no se filtren. Si tu token se
  llama `MI_API_KEY` vas a ver un warning de variable vacia y el servidor no va
  a autenticar. Pasalo por `env`, o por el CLI con `--header`.
- **Un `.mcp.json` de proyecto pide aprobacion** la primera vez, y necesita que
  el workspace sea de confianza. En sesiones no interactivas se carga sin
  preguntar. Para reiniciar lo aprobado: `claude mcp reset-project-choices`.
- **Empieza en `local`**, y sube a `project` o `user` cuando ya sepas que lo
  usas.

## Permisos

Las herramientas MCP se nombran `mcp__<servidor>__<herramienta>` y se pueden
pre-aprobar en `settings.json` como cualquier otra:

```json
{
  "permissions": {
    "allow": [
      "mcp__notion__search",
      "mcp__github__.*"
    ]
  }
}
```

## Antes de agregar un servidor

- [ ] Sabes que hace y quien lo mantiene. Va a correr con tus credenciales.
- [ ] Los secretos van por `${VAR}`, nunca escritos en el archivo.
- [ ] El nombre de la variable no cae en el filtro anti-fuga si la usas en
      `url` o `headers`.
- [ ] El alcance es el mas estrecho que sirva.
- [ ] Si es `project`, el equipo sabe que ese `.mcp.json` esta commiteado.
- [ ] Documentado abajo.

## Catalogo

Todavia ninguno configurado. Esta carpeta existe para cuando haga falta.
