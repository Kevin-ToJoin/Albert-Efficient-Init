# Deuda tecnica

Registro de pendientes, atajos y decisiones diferidas de este repositorio.
Lo mantiene el comando `/finalizar` de Claude Code.

Convencion: cada item lleva `[M]` si requiere accion manual del usuario
(credenciales, decision de producto, acceso, algo fuera del repo), o `[A]` si
es trabajo que un agente puede hacer solo.

## Abiertos

- [ ] [A] No hay CI. Un workflow que corra `bash -n` sobre los tres scripts,
      `claude plugin validate` sobre el plugin y el marketplace, y el
      extract-and-run del bloque `!` en los cuatro estados de repo, evitaria
      regresiones silenciosas. - `.github/workflows/` (no existe)
- [ ] [A] Las pruebas de instalador y desinstalador de bash fueron manuales en
      un sandbox; no quedaron como script reejecutable. Convertir esa secuencia
      en `tests/install_test.sh` (analogo al `tests/install_test.ps1` que ya
      existe para PowerShell) para poder correrla desde el CI de arriba.
- [ ] [A] `/finalizar` nunca se ha ejecutado como slash command real. Se probo
      su bloque `!` por separado y el procedimiento se ejecuto a mano. Falta una
      corrida de punta a punta despues de instalarlo con
      `install.sh --skills`. - `plugins/albert/skills/finalizar/SKILL.md`
- [ ] [A] Confirmar que `allowed-tools: Bash(git *) ...` pre-aprueba de verdad.
      La doc de slash commands usa esa forma con espacio; la de permisos en
      `settings.json` usa `Bash(git:*)` con dos puntos, y la referencia de
      plugins no lista el campo. Si la forma es incorrecta el unico efecto es
      que salen prompts de confirmacion, no un
      fallo. - `plugins/albert/skills/finalizar/SKILL.md:6`
- [ ] [A] `bootstrap.sh` deja `~/.albert-efficient-init` en HEAD desprendido al
      actualizar (`checkout --detach FETCH_HEAD`). Funciona y evita conflictos
      de merge, pero confunde si el usuario entra a ese directorio a
      editar. - `bootstrap.sh:32`
- [ ] [A] El checklist de comandos nuevos es manual; no hay script que lo
      ejecute. - `docs/comandos.md:127`
- [ ] [A] El campo `version` esta duplicado entre
      `plugins/albert/.claude-plugin/plugin.json` y
      `.claude-plugin/marketplace.json`. Hay que subirlo en los dos a mano y
      nada avisa si se desincronizan.

## Cerrados

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

### 2026-09-18 - rama `claude/webhook-finalizar-setup-yiu5os`

Conversion del repo en un toolkit de slash commands: marketplace de plugins,
plugin `albert` con `plugins/albert/skills/` como fuente unica, comando
`/finalizar`, instalador reescrito con cuatro modos de enganche, `bootstrap.sh`
para el one-liner, y documentacion de autoria de comandos.

Nuevos pendientes: 8 | Cerrados: 4
