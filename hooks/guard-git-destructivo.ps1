<#
.SYNOPSIS
  Hook PreToolUse: bloquea comandos de git que destruyen trabajo.

.DESCRIPTION
  Lee el JSON del hook por stdin, mira tool_input.command, y sale con codigo 2
  si el comando coincide con algo destructivo. En un PreToolUse, el codigo 2
  bloquea la llamada y el stderr se le devuelve a Claude como explicacion.

  Falla abierto a proposito: si el JSON no parsea o no hay comando, sale 0 y
  deja pasar. Un guard roto que bloquea todo es peor que no tener guard.

  Registrarlo en settings.json con matcher "Bash". Ver README.md.
#>

$ErrorActionPreference = 'Stop'

try {
  $raw = [Console]::In.ReadToEnd()
  if (-not $raw) { exit 0 }
  $payload = $raw | ConvertFrom-Json
} catch {
  exit 0
}

$cmd = $payload.tool_input.command
if (-not $cmd) { exit 0 }

# Cada regla: un patron y el motivo que se le devuelve a Claude.
# Se evalua por comando suelto para que "git status; git push --force" no se
# escape partiendo la linea.
$reglas = @(
  @{
    Test   = { param($c) $c -match 'git\s+push\b' -and
               ($c -match '--force(?!-with-lease)' -or $c -match '(^|\s)-f(\s|$)') }
    Motivo = 'git push --force puede sobrescribir trabajo que ya esta en el remoto. Usa --force-with-lease, o pideselo al usuario para que lo ejecute el.'
  },
  @{
    Test   = { param($c) $c -match 'git\s+reset\b[^|;&]*--hard' }
    Motivo = 'git reset --hard borra los cambios sin commitear y no hay forma de recuperarlos. Si de verdad hace falta, guarda antes con git stash -u.'
  },
  @{
    Test   = { param($c) $c -match 'git\s+clean\b[^|;&]*\s-[a-zA-Z]*f' }
    Motivo = 'git clean -f borra archivos sin trackear de forma irreversible, incluido trabajo en curso. Corre git clean -n primero para ver que se llevaria.'
  },
  @{
    # -cmatch, sensible a mayusculas: -D fuerza el borrado, -d es la variante
    # segura y no se debe bloquear. El -match normal de PowerShell ignora la
    # caja y bloquearia las dos.
    Test   = { param($c) $c -cmatch 'git\s+branch\b[^|;&]*\s-D\b' }
    Motivo = 'git branch -D borra una rama aunque tenga commits sin mergear. Usa -d, que falla si quedaria trabajo huerfano.'
  }
)

# Separa por ; && || | para evaluar cada comando encadenado por su cuenta.
$partes = [regex]::Split($cmd, '(?:&&|\|\||;|\|)')

foreach ($parte in $partes) {
  foreach ($regla in $reglas) {
    if (& $regla.Test $parte) {
      [Console]::Error.WriteLine("Bloqueado por el hook guard-git-destructivo.")
      [Console]::Error.WriteLine("")
      [Console]::Error.WriteLine("  Comando: $($parte.Trim())")
      [Console]::Error.WriteLine("  Motivo:  $($regla.Motivo)")
      [Console]::Error.WriteLine("")
      [Console]::Error.WriteLine("No reintentes con una variante para esquivar el guard. Si el usuario lo")
      [Console]::Error.WriteLine("pide explicitamente, explicale que tiene que ejecutarlo el a mano.")
      exit 2
    }
  }
}

exit 0
