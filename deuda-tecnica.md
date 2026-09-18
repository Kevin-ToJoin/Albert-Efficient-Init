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

Nuevos pendientes: 2 | Cerrados: 3

### 2026-09-18 - rama `claude/webhook-finalizar-setup-yiu5os`

Conversion del repo en un toolkit de slash commands: marketplace de plugins,
plugin `albert` con `plugins/albert/skills/` como fuente unica, comando
`/finalizar`, instalador reescrito con cuatro modos de enganche, `bootstrap.sh`
para el one-liner, y documentacion de autoria de comandos.

Nuevos pendientes: 8 | Cerrados: 4
