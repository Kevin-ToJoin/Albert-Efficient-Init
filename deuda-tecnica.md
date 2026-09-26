# Deuda tecnica

Registro de pendientes, atajos y decisiones diferidas de este repositorio.
Lo mantiene el comando `/albert:finalizar` de Claude Code.

Convencion: cada item lleva `[M]` si requiere accion manual del usuario
(credenciales, decision de producto, acceso, algo fuera del repo), o `[A]` si
es trabajo que un agente puede hacer solo.

## Abiertos

- [ ] [A] `/albert:finalizar` y `/albert:lanzar-dominio` pasan el chequeo de su
      bloque `!` y arrancan en una invocacion real (`claude -p` con
      `--plugin-dir`), pero ninguna se ha visto terminar su procedimiento
      entero: el merge y push de `finalizar` ni los archivos que genera
      `lanzar-dominio`. - `plugin/skills/`
- [ ] [M] El plugin nunca se ha instalado desde GitHub, solo cargado con
      `--plugin-dir`. Falta, tras el push a `main`: en un repo destino real,
      `/plugin marketplace add Kevin-ToJoin/Albert-Efficient-Init`, instalar con
      alcance de proyecto, `/albert:iniciar`, commitear, y que **otra persona**
      clone el repo y reciba el plugin al aceptar la confianza de la carpeta.
      Es la promesa central del toolkit y esta sin probar. - `README.md`
- [ ] [M] Migrar la maquina Windows del modelo de junction. Ahi siguen
      `~/.claude/skills` y `~/.claude/agents` apuntando a carpetas que ya no
      existen, y `~/.claude/settings.json` registra los guards con rutas a
      `hooks/` que tampoco existen: `node` falla en cada Bash con un error no
      bloqueante y **los guards dejan de proteger**. Quitar
      las dos junctions y el bloque de hooks, e integrar el plugin.
- [ ] [A] `"autoUpdate": true` en el `.claude/settings.json` del repo destino
      esta documentado para cualquier archivo de settings, pero no se ha visto
      actualizar nada: hace falta un push, abrir sesion en un repo integrado y
      ver `Plugin updated`. Sin eso, el fallback es
      `/plugin marketplace update albert-efficient-init`. - `plugin/skills/iniciar/SKILL.md`
- [ ] [A] `/albert:iniciar` no puede escribir `.claude/settings.json` en una
      sesion no interactiva: Claude Code protege `.claude/` y lo deniega aun con
      `acceptEdits`. En interactiva pide confirmacion, que es lo correcto, pero
      no se ha probado ese camino. - `plugin/skills/iniciar/SKILL.md`
- [ ] [A] `auditor-deuda` nunca se ha ejecutado. Se escribio contra la
      referencia de subagentes pero no se ha invocado ni una vez, asi que no se
      sabe si el reporte sale en el formato pedido ni si el cruce contra
      `## Abiertos` filtra bien. - `plugin/agents/auditor-deuda.md`
- [ ] [A] El campo `memory: project` de `auditor-deuda` esta puesto sin
      verificar. La referencia lo documenta como alcance de memoria persistente
      pero no describe como escribe el agente en ella; hace falta comprobar en
      dos sesiones distintas si de verdad recuerda algo. Si no funciona, el
      unico efecto es que no recuerda nada. - `plugin/agents/auditor-deuda.md:7`
- [ ] [A] La forma `exec` del registro (`command` + `args`) sigue sin probarse.
      La doc la recomienda pero no dice desde que version existe `args`, asi que
      el registro real se hizo con la forma shell, que si esta verificada en la
      2.1.201. Si algun dia se confirma `exec`, es marginalmente mas robusto con
      rutas raras. - `docs/hooks.md`
- [ ] [A] `auditor-seguridad` nunca se ha ejecutado contra un proyecto real.
      Los nueve puntos y el formato de reporte estan escritos, pero no se sabe
      si distingue bien "no esta" de "no lo veo", que es lo unico que lo hace
      util. Probarlo contra una app con base de datos, no contra este
      repo. - `plugin/agents/auditor-seguridad.md`
- [ ] [A] La lista de nueve puntos de `auditor-seguridad` se reconstruyo desde
      capturas donde solo se veian numerados el 6 al 10; los otros cuatro salen
      de slides sueltas. El contenido es estandar y se sostiene solo, pero la
      numeracion puede no coincidir con la lista
      original. - `plugin/agents/auditor-seguridad.md`
- [ ] [A] La plantilla de `docs/mcp.json.ejemplo` no se ha probado contra ningun servidor real.
      Las cuatro formas de transporte salen de la doc oficial y el JSON parsea,
      pero nadie ha levantado un servidor con ella. En particular no se ha
      comprobado en la practica el filtro anti-fuga de variables con `KEY` o
      `TOKEN` en el nombre. - `docs/mcp.json.ejemplo`
- [ ] [A] No hay CI. Lo unico que queda mecanicamente testeable tras quitar los
      instaladores es el extract-and-run de los bloques `!` de cada `SKILL.md`
      en los cuatro estados de repo. Un workflow minimo lo
      cubriria. - `.github/workflows/` (no existe)
- [ ] [A] El checklist de comandos nuevos es manual; no hay script que lo
      ejecute. - `docs/comandos.md:131`

## Cerrados

- [x] 2026-09-26 - Las tres skills con bloque `!` fallaban como slash command
      real, aunque su bloque daba `EXIT=0` en bash en los cuatro estados.
      Claude Code pasa el bloque por su chequeo de permisos y rechazaba los
      grupos `{ ...; }` ("expansion obfuscation" y `compound_statement`), un
      pipe dentro de un `if` de una linea, y `grep`, `head` y `cut` por no estar
      en `allowed-tools`. Reescritos los tres bloques; verificados con
      `claude -p` y `--plugin-dir`. De paso, `finalizar` mandaba revisar una
      seccion `archivos-tocados-vs-HEAD` que no existia. - `plugin/skills/`
- [x] 2026-09-26 - `allowed-tools: Bash(grep *)` con espacio si pre-aprueba:
      agregarlo fue lo que desbloqueo el bloque de `iniciar` en `-p`.
- [x] 2026-09-26 - Los guards corren fuera de Windows: los 47 casos pasan en
      macOS, y registrados desde `plugin/hooks/hooks.json` bloquearon un
      `git branch -D` en una sesion real, con el mensaje llegando a Claude.
- [x] 2026-09-26 - Las reglas ya no se copian a mano: `/albert:iniciar` escribe
      el `CLAUDE.md` en el repo destino y los perfiles son skills.
- [x] 2026-09-26 - Desaparece el pendiente de la junction silenciosa: ya no hay
      junction. Un plugin que no carga aparece en la pestaña Errors de
      `/plugin`.
- [x] 2026-09-19 - Falso positivo de `guard-secretos`, encontrado en su primer
      uso real y costo dos intentos. Bloqueo un `git commit` cuyo **mensaje**
      mencionaba `git add .env`: hablar de un archivo no es commitearlo. El
      primer arreglo aparto el texto entrecomillado antes de trocear, y fallo
      igual, porque el mensaje llevaba comillas dobles dentro y el
      emparejamiento se desalineaba. La leccion es que parsear sintaxis de
      shell con expresiones regulares no se sostiene. El arreglo bueno es no
      intentarlo: el escaneo de rutas corre solo en `git add` y
      `git stash push`, cuyos argumentos **son** rutas, y en `git commit` manda
      el index, que es la verdad de git y no una suposicion sobre el texto.
      Siete casos de regresion, heredoc y comillas anidadas
      incluidos. - `hooks/guard-secretos.js`
- [x] 2026-09-19 - Los dos guards verificados de punta a punta en una sesion
      real de Claude Code, no solo con JSON simulado por stdin. Registrados en
      `~/.claude/settings.json` global con forma shell, `git branch -D` y
      `git add .env` quedaron bloqueados con su mensaje, y `git status` y la
      variante segura `git branch -d` pasaron sin tocarse. El cambio de
      `settings.json` surtio efecto **sin reiniciar** la sesion.
- [x] 2026-09-19 - Enganchadas las junctions de `~/.claude/skills` y
      `~/.claude/agents` al repo. Las cuatro skills y agentes resuelven a traves
      del enlace.
- [x] 2026-09-18 - Tres pendientes desaparecen con el refactor a carpeta pura,
      no por haberse resuelto: el `tests/install_test.sh` que faltaba, el HEAD
      desprendido que dejaba `bootstrap.sh`, y el campo `version` duplicado
      entre `plugin.json` y `marketplace.json`. Los cinco scripts y los dos
      manifiestos que los causaban ya no existen.
- [x] 2026-09-18 - Verificados `install.ps1` y `uninstall.ps1` en Windows
      PowerShell 5.1 real (antes solo probados por inspeccion, sin PowerShell
      disponible). Los 4 modos de enganche, la idempotencia, `-Force`, `-List`,
      el merge de `settings.json` preservando claves ajenas y el guard de JSON
      invalido funcionan igual que la version bash, incluso con espacios en la
      ruta (el caso real de este usuario en Windows). Encontrada y corregida
      una brecha de paridad: `uninstall.ps1` no borraba el directorio
      `skills` si quedaba vacio (bash si lo hace via
      `rmdir ... || true`). Arnes de pruebas reejecutable en
      `tests/install_test.ps1`. - `uninstall.ps1`
- [x] 2026-09-18 - `git log HEAD --not main master` fallaba entero si `master`
      no existia, devolviendo vacio en cualquier repo moderno. Encadenado con
      `||` por rama.
- [x] 2026-09-18 - `git remote` sin remotos sale 0 imprimiendo nada, asi que el
      `|| echo "(sin remoto)"` nunca se disparaba. Ahora pasa por `grep .`.
- [x] 2026-09-18 - `git rev-parse --abbrev-ref HEAD` imprime `HEAD` y sale 128
      en un repo sin commits, lo que se leia como "no es un repo git".
      Sustituido por `git symbolic-ref --short -q HEAD`.
- [x] 2026-09-18 - Los guardas `[ "$X" -eq 1 ] && funcion` al final de
      `install.sh` abortaban el script bajo `set -e` cuando la condicion era
      falsa, asi que `--skills` nunca llegaba a `--attach` ni imprimia `Done.`.
      Convertidos a bloques `if`.

## Bitacora

### 2026-09-26 - rama `toolkit-plugin` (alcance definitivo)

Se fija el alcance del proyecto: **un toolkit que se integra en cualquier otro
repositorio** y le llega a todo su equipo, con skills, subagentes, hooks, MCP y
la plantilla de `CLAUDE.md`. Todo el repo se reescribio para apuntar ahi.

Venia de dos rumbos que chocaron en `main`: el toolkit de junctions a
`~/.claude` (global, personal) y un commit que lo convertia en libro de
consulta. El libro (`book/`) y el archivo de iteraciones (`archive/`) se
borraron; siguen en el historial y en la rama local `backup/main-local-e87620b`.
El modo global por junction tambien se quito.

El mecanismo es el plugin de Claude Code, que la vuelta del 18 habia
descartado. La diferencia es que entonces venia envuelto en cinco scripts de
instalacion; ahora el plugin es el unico mecanismo y no hay instalador. Lo
decidio la documentacion: un plugin cuyo marketplace lo declara con ruta
relativa se carga solo en cuanto un colaborador confia en la carpeta, asi que
integrar el toolkit en un repo es commitear un `.claude/settings.json` de diez
lineas. Nada mas da eso.

Tres cosas de la doc condicionaron la estructura: un `CLAUDE.md` en la raiz de
un plugin no se carga, por eso el plugin vive en `plugin/` y el `CLAUDE.md` lo
escribe la skill nueva `/albert:iniciar`; sin `version`, los repos siguen los
commits, por eso no se declara; y los perfiles, que eran archivos a copiar, se
volvieron skills que Claude carga solo cuando aplican.

Probarlo de verdad destapo que ninguna de las skills con bloque `!` habia
funcionado nunca como comando real. Queda anotado en Cerrados y en
`docs/comandos.md`, con la prueba que si lo detecta.

Nuevos pendientes: 5 | Cerrados: 5

### 2026-09-18 - rama `seguridad-y-dominio`

Entra un lote de buenas practicas de seguridad y de puesta en marcha de
dominio, repartido segun las guias que estrenaron las carpetas la vuelta
anterior. Sirvio de primera prueba real de que esas guias deciden bien:

- Lo que no puede fallar nunca fue a `hooks/`: `guard-secretos.ps1` impide que
  un `.env`, un `.pem` o un token literal lleguen a un commit, y mira tambien
  el index, que es por donde se filtran de verdad. Deja pasar `.env.example`.
- El checklist de nueve puntos fue a `agents/`: barrer un repo entero y
  devolver un reporte corto es exactamente la forma de un subagente.
- Los principios de fondo fueron a `rules/Efficiency/rules-seguridad.md`, el
  tercer perfil, que se carga solo cuando la tarea toca auth, datos o secretos.
- El procedimiento de dominio fue a `skills/`, porque tiene pasos y criterio y
  lo disparas tu.
- **A `mcp/` no fue nada**, y es la decision que mas costo: ninguno de estos
  tips necesita un sistema externo, y meter uno ahi habria roto la regla del
  propio `mcp/README.md` sobre no agregar lo que "podria servir".

El guard de secretos tiene 27 pruebas, incluida una que monta un repo git de
verdad en Temp para cubrir el caso que no se puede simular con el texto del
comando: `git commit` con el `.env` ya en el index. Esa prueba fallo al
principio por un error del propio test, no del hook: `git restore --staged`
necesita un `HEAD` y el repo recien inicializado no tiene ninguno.

Despues, un cambio de requisito obligo a rehacer los dos guards: el toolkit se
usa desde varias maquinas, tambien macOS y Linux y sesiones remotas, y un
`.ps1` no protege nada fuera de Windows. Portados a Node, sin dependencias, una
sola implementacion. Se borraron los cuatro `.ps1` y las pruebas se unificaron
en `guards.test.js`, mismos 47 casos.

La duda que lo destapo fue buena: "los hooks se corren en Claude Code, no?".
Claude Code decide *cuando*, pero el comando lo ejecuta el sistema operativo,
que es justo por lo que el lenguaje importa. La propia leccion lo deja ver
cuando habla de correr `gofmt` o Prettier: son binarios de tu maquina.

Se eligio Node y no bash por tres razones: `JSON.parse` de verdad en vez de
regex sobre JSON, que en un guard de seguridad importa; `jq` no esta instalado
en esta maquina y casi en ninguna; y la doc oficial recomienda exactamente el
patron `node` + script en forma exec para hooks multiplataforma. El registro
pasa a forma exec (`command` + `args`), que al no pasar por ningun shell evita
la pregunta de Git Bash contra PowerShell en Windows.

De paso quedo documentado en `hooks/README.md` por que los hooks son la unica
parte del repo que depende del sistema: las skills, los agents y las rules son
datos que interpreta Claude Code, y los hooks son procesos que lanza el SO.

Nuevos pendientes: 6 | Cerrados: 0

### 2026-09-18 - rama `main` (refactor a carpeta pura)

El instalador se comia el repo: cinco scripts, cuatro modos de enganche, un
marketplace y un plugin, todo para copiar un `SKILL.md`. Se cambio por una
junction: `~/.claude/skills` apunta a `skills/` del repo y actualizar es
`git pull`. Borrados `bootstrap.sh`, `install.{sh,ps1}`, `uninstall.{sh,ps1}`,
`tests/`, `.claude-plugin/` y `plugins/`. El contenido subio a la raiz en tres
carpetas de proposito unico: `skills/`, `hooks/`, `rules/`.

Verificado en esta maquina que una junction de Windows cruza de `C:` a `E:` sin
admin y que borrarla no toca el target. Confirmado en la doc que los hooks no
pueden ser file-drop: siempre necesitan una entrada en `settings.json`, salvo
los declarados en el frontmatter de una skill, que si viajan con el repo.

Ademas, el repo gana su primer `CLAUDE.md`: importa con `@` la plantilla que
distribuye (`rules/CLAUDE-root-template.md`) y le suma las mecanicas propias,
para que las reglas base tengan una sola fuente en vez de dos copias que se
desincronizan. La plantilla se reescribio en espanol y se dejo autocontenida,
que es requisito para poder copiarla sola a otro proyecto.

Despues se sumo `agents/`, cuarta carpeta y segunda junction, con
`auditor-deuda`: barre el repo y reporta solo la deuda que no esta ya en este
archivo. Se le quitaron `Write` y `Edit` a proposito, para que el unico que
escriba aqui siga siendo `/finalizar`.

De paso, la leccion del curso que describe `/agents` con asistente de creacion
va por detras: desde la v2.1.198 ese asistente no existe, y aqui corre la
2.1.201.

Cierre de la vuelta: el toolkit pasa a cubrir las cinco piezas de Claude Code.
`hooks/` estrena `guard-git-destructivo.ps1`, que bloquea `push --force`,
`reset --hard`, `clean -f` y `branch -D` por `PreToolUse` con exit 2. Es el
ejemplo de la tesis de la leccion: la regla ya existia en el prompt de
`/finalizar` y se cumplia casi siempre; el hook la vuelve determinista. Sus
pruebas encontraron un bug real antes de commitear: `-match` en PowerShell
ignora mayusculas, asi que la primera version tambien bloqueaba `git branch -d`,
que es la variante segura. Corregido con `-cmatch`.

`mcp/` entra como quinta carpeta, con plantilla de los cuatro transportes. No se
engancha con junction: la config de MCP vive en `.mcp.json` del proyecto o en
`~/.claude.json`, asi que se copia, como `rules/`.

Y las cuatro carpetas enganchables ganan un README con que merece guardarse en
cada una y que no, con la misma tabla skill/agente/hook repetida a proposito en
las tres, que es la decision que mas se equivoca.

Nuevos pendientes: 7 | Cerrados: 3

### 2026-09-18 - rama `claude/webhook-finalizar-setup-yiu5os`

Conversion del repo en un toolkit de slash commands: marketplace de plugins,
plugin `albert` con `plugins/albert/skills/` como fuente unica, comando
`/finalizar`, instalador reescrito con cuatro modos de enganche, `bootstrap.sh`
para el one-liner, y documentacion de autoria de comandos.

Nuevos pendientes: 8 | Cerrados: 4
