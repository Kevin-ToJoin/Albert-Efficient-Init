# Deuda tecnica

Registro de pendientes, atajos y decisiones diferidas de este repositorio.
Lo mantiene el comando `/finalizar` de Claude Code.

Convencion: cada item lleva `[M]` si requiere accion manual del usuario
(credenciales, decision de producto, acceso, algo fuera del repo), o `[A]` si
es trabajo que un agente puede hacer solo.

## Abiertos

- [ ] [A] `/finalizar` nunca se ha ejecutado como slash command real. Se probo
      su bloque `!` por separado y el procedimiento se ejecuto a mano. Falta una
      corrida de punta a punta despues de engancharlo con la
      junction. - `skills/finalizar/SKILL.md`
- [ ] [A] `auditor-deuda` nunca se ha ejecutado. Se escribio contra la
      referencia de subagentes pero no se ha invocado ni una vez, asi que no se
      sabe si el reporte sale en el formato pedido ni si el cruce contra
      `## Abiertos` filtra bien. - `agents/auditor-deuda.md`
- [ ] [A] El campo `memory: project` de `auditor-deuda` esta puesto sin
      verificar. La referencia lo documenta como alcance de memoria persistente
      pero no describe como escribe el agente en ella; hace falta comprobar en
      dos sesiones distintas si de verdad recuerda algo. Si no funciona, el
      unico efecto es que no recuerda nada. - `agents/auditor-deuda.md:7`
- [ ] [M] Ningun hook se ha registrado en un `settings.json` real. Las 47
      pruebas de `guard-git-destructivo` y `guard-secretos` les meten el JSON a
      mano por stdin, fiel al esquema documentado, pero falta verlos bloquear
      de verdad una llamada de Claude Code. Registrarlos es decision del
      usuario. - `hooks/`
- [ ] [A] `auditor-seguridad` nunca se ha ejecutado contra un proyecto real.
      Los nueve puntos y el formato de reporte estan escritos, pero no se sabe
      si distingue bien "no esta" de "no lo veo", que es lo unico que lo hace
      util. Probarlo contra una app con base de datos, no contra este
      repo. - `agents/auditor-seguridad.md`
- [ ] [A] `/lanzar-dominio` no se ha invocado como slash command. Su bloque `!`
      si esta probado en cuatro estados de proyecto (vacio, con `package.json`,
      con carpeta publica, y este repo) y sale `EXIT=0` en los
      cuatro. - `skills/lanzar-dominio/SKILL.md`
- [ ] [A] La lista de nueve puntos de `auditor-seguridad` se reconstruyo desde
      capturas donde solo se veian numerados el 6 al 10; los otros cuatro salen
      de slides sueltas. El contenido es estandar y se sostiene solo, pero la
      numeracion puede no coincidir con la lista
      original. - `agents/auditor-seguridad.md`
- [ ] [A] La plantilla de `mcp/` no se ha probado contra ningun servidor real.
      Las cuatro formas de transporte salen de la doc oficial y el JSON parsea,
      pero nadie ha levantado un servidor con ella. En particular no se ha
      comprobado en la practica el filtro anti-fuga de variables con `KEY` o
      `TOKEN` en el nombre. - `mcp/mcp.json.ejemplo`
- [ ] [A] Confirmar que `allowed-tools: Bash(git *) ...` pre-aprueba de verdad.
      La doc de slash commands usa esa forma con espacio; la de permisos en
      `settings.json` usa `Bash(git:*)` con dos puntos. Si la forma es
      incorrecta el unico efecto es que salen prompts de confirmacion, no un
      fallo. - `skills/finalizar/SKILL.md:6`
- [ ] [A] No hay CI. Lo unico que queda mecanicamente testeable tras quitar los
      instaladores es el extract-and-run de los bloques `!` de cada `SKILL.md`
      en los cuatro estados de repo. Un workflow minimo lo
      cubriria. - `.github/workflows/` (no existe)
- [ ] [A] El checklist de comandos nuevos es manual; no hay script que lo
      ejecute. - `docs/comandos.md:131`
- [ ] [A] Al quitar `install.sh --rules` las reglas de `rules/` se copian a mano.
      Un comando `/init-reglas` que las escriba en el repo actual y añada las
      dos lineas al `.gitignore` recuperaria esa comodidad sin reintroducir un
      instalador. Es justo el tipo de cosa para la que sirve `skills/`.
- [ ] [M] Nada verifica que la junction `~/.claude/skills` este puesta. Si no lo
      esta, los comandos simplemente no aparecen y no hay mensaje de error que
      lo explique. El README lo documenta, pero es un paso manual y silencioso.

## Cerrados

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

Nuevos pendientes: 4 | Cerrados: 0

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
