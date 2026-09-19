<#
.SYNOPSIS
  Hook PreToolUse: impide que un secreto llegue a un commit.

.DESCRIPTION
  Vigila los comandos de git y bloquea dos cosas:

    1. Stagear o commitear archivos de credenciales (.env, *.pem, id_rsa,
       credentials.json...). Las plantillas tipo .env.example si pasan: estan
       hechas para commitearse.
    2. Comandos que llevan un secreto literal escrito dentro (tokens de
       GitHub, claves de OpenAI, claves de AWS, bloques PEM).

  En un PreToolUse, el codigo 2 bloquea la llamada y el stderr se le devuelve
  a Claude como explicacion.

  Falla abierto a proposito: si el JSON no parsea o git no responde, sale 0.
  Un guard roto que bloquea todo acaba desactivado, y entonces no protege nada.

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

function Deny {
  param([string]$Que, [string]$Motivo, [string]$Salida)
  [Console]::Error.WriteLine("Bloqueado por el hook guard-secretos.")
  [Console]::Error.WriteLine("")
  [Console]::Error.WriteLine("  Detectado: $Que")
  [Console]::Error.WriteLine("  Motivo:    $Motivo")
  [Console]::Error.WriteLine("  Que hacer: $Salida")
  [Console]::Error.WriteLine("")
  [Console]::Error.WriteLine("No lo reintentes esquivando el guard. Un secreto commiteado sigue en el")
  [Console]::Error.WriteLine("historial aunque despues lo borres, y hay que rotarlo igual.")
  exit 2
}

# --- 1. Secretos literales escritos en el propio comando ----------------------

$patronesSecreto = @(
  @{ Re = 'ghp_[A-Za-z0-9]{20,}';                Que = 'token de acceso personal de GitHub' },
  @{ Re = 'github_pat_[A-Za-z0-9_]{20,}';        Que = 'token de acceso personal de GitHub' },
  @{ Re = 'sk-[A-Za-z0-9]{32,}';                 Que = 'clave de API estilo OpenAI' },
  @{ Re = 'AKIA[0-9A-Z]{16}';                    Que = 'access key de AWS' },
  @{ Re = '-----BEGIN [A-Z ]*PRIVATE KEY-----';  Que = 'clave privada en formato PEM' },
  @{ Re = 'xox[baprs]-[A-Za-z0-9-]{10,}';        Que = 'token de Slack' }
)

foreach ($p in $patronesSecreto) {
  if ($cmd -match $p.Re) {
    Deny $p.Que `
      'el comando lleva la credencial escrita en texto plano, y eso acaba en el historial de shell y probablemente en un archivo.' `
      'pon el valor en una variable de entorno o en un .env gitignoreado, y en el codigo referencia la variable.'
  }
}

# --- 2. Archivos de credenciales en git add / git commit ----------------------

if ($cmd -notmatch 'git\s+(add|commit|stash\s+push)\b') { exit 0 }

# Nombres que son credenciales. Las plantillas quedan fuera a proposito.
$reSensible = '(^|/)(\.env(\.[A-Za-z0-9_-]+)?|credentials\.json|secrets\.json|serviceAccount[A-Za-z0-9_-]*\.json|id_rsa|id_ed25519|id_dsa|.+\.(pem|pfx|p12|keystore|jks))$'
$rePlantilla = '\.(example|sample|template|dist|ejemplo)$'

function Test-Sensible {
  param([string]$Ruta)
  $r = $Ruta.Trim().Trim('"').Trim("'") -replace '\\', '/'
  if (-not $r) { return $false }
  if ($r -match $rePlantilla) { return $false }
  return ($r -match $reSensible)
}

$encontrados = New-Object System.Collections.Generic.List[string]

# 2a. Rutas nombradas explicitamente en el comando.
foreach ($token in ($cmd -split '\s+')) {
  if ($token -like '-*') { continue }
  if (Test-Sensible $token) { [void]$encontrados.Add($token) }
}

# 2b. Lo que ya este en el index. Cubre "git add ." seguido de "git commit".
try {
  $cwd = $payload.cwd
  if ($cwd -and (Test-Path -PathType Container $cwd)) {
    Push-Location $cwd
    try {
      $staged = & git diff --cached --name-only 2>$null
      if ($LASTEXITCODE -eq 0 -and $staged) {
        foreach ($f in $staged) {
          if (Test-Sensible $f) { [void]$encontrados.Add($f) }
        }
      }
    } finally { Pop-Location }
  }
} catch {
  # git no disponible o no es un repo: no bloqueamos por eso.
}

if ($encontrados.Count -gt 0) {
  $lista = ($encontrados | Sort-Object -Unique) -join ', '
  Deny "archivo de credenciales en el commit: $lista" `
    'un secreto commiteado queda en el historial para siempre, y en un repo publico se considera filtrado desde el primer push.' `
    'agregalo al .gitignore, quitalo del index con git restore --staged <archivo>, y si necesitas versionar su forma, commitea un .env.example sin valores reales.'
}

exit 0
