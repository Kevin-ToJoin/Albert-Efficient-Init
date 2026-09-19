<#
.SYNOPSIS
  Pruebas de guard-secretos.ps1.

.DESCRIPTION
  Le mete al hook el mismo JSON que le manda Claude Code por stdin y comprueba
  el codigo de salida: 2 bloquea, 0 deja pasar.

  Monta ademas un repo git de verdad en Temp para probar el caso que no se
  puede simular con el texto del comando: "git commit" cuando ya hay un .env
  en el index, que es como se filtra un secreto de verdad (git add . y a correr).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File hooks\guard-secretos.test.ps1
#>
$HookPath = Join-Path $PSScriptRoot 'guard-secretos.ps1'
$fail = 0

function Invoke-Hook {
  param([string]$Command, [string]$Cwd)
  $obj = @{
    hook_event_name = 'PreToolUse'
    tool_name       = 'Bash'
    tool_input      = @{ command = $Command }
  }
  if ($Cwd) { $obj.cwd = $Cwd }
  ($obj | ConvertTo-Json -Depth 5 -Compress) |
    & powershell -NoProfile -ExecutionPolicy Bypass -File $HookPath 2>$null | Out-Null
  return $LASTEXITCODE
}

function Test-Cmd {
  param([string]$Command, [int]$Esperado, [string]$Cwd, [string]$Nota)
  $code = Invoke-Hook -Command $Command -Cwd $Cwd
  $etiqueta = if ($Esperado -eq 2) { 'BLOQUEA' } else { 'permite' }
  $corto = if ($Command.Length -gt 58) { $Command.Substring(0, 55) + '...' } else { $Command }
  if ($code -eq $Esperado) {
    Write-Host ("  PASS  {0,-7} {1}" -f $etiqueta, $corto)
  } else {
    Write-Host ("  FAIL  {0,-7} {1}  (esperaba {2}, dio {3}) {4}" -f $etiqueta, $corto, $Esperado, $code, $Nota) -ForegroundColor Red
    $script:fail++
  }
}

Write-Host "=== Archivos de credenciales nombrados en el comando ==="
Test-Cmd 'git add .env'                          2
Test-Cmd 'git add config/.env.production'        2
Test-Cmd 'git add id_rsa'                        2
Test-Cmd 'git add certs/server.pem'              2
Test-Cmd 'git add credentials.json'              2
Test-Cmd 'git add serviceAccountKey.json'        2
Test-Cmd 'git commit -m "wip" .env.local'        2

Write-Host ""
Write-Host "=== Plantillas: SI se commitean ==="
Test-Cmd 'git add .env.example'                  0  'plantilla'
Test-Cmd 'git add .env.template'                 0  'plantilla'
Test-Cmd 'git add mcp/mcp.json.ejemplo'          0  'plantilla de este repo'

Write-Host ""
Write-Host "=== Secretos literales dentro del comando ==="
Test-Cmd 'echo ghp_abcdefghijklmnopqrstuvwxyz012345 > t.txt'            2
Test-Cmd 'export OPENAI_API_KEY=sk-abcdefghijklmnopqrstuvwxyz0123456789' 2
Test-Cmd 'aws configure set k AKIAIOSFODNN7EXAMPLE'                      2
Test-Cmd 'echo "-----BEGIN RSA PRIVATE KEY-----" >> id'                  2

Write-Host ""
Write-Host "=== NO debe tocar ==="
Test-Cmd 'git add src/index.js'                  0
Test-Cmd 'git add README.md'                     0
Test-Cmd 'git status'                            0
Test-Cmd 'npm install'                           0
Test-Cmd 'git commit -m "docs: explicar ${AIRTABLE_API_KEY}"' 0 'placeholder, no secreto real'
Test-Cmd 'git log --oneline'                     0
Test-Cmd 'cat .env'                              0  'leerlo no es commitearlo'

Write-Host ""
Write-Host "=== Repo real: .env ya en el index ==="
$Sandbox = Join-Path $env:TEMP 'aei-secretos test'
if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Path $Sandbox -Force | Out-Null
Push-Location $Sandbox
try {
  & git init -q 2>$null
  & git config user.email 'test@test'; & git config user.name 'test'
  'API_KEY=valor-real-secreto' | Set-Content -Path (Join-Path $Sandbox '.env') -Encoding utf8
  'hola' | Set-Content -Path (Join-Path $Sandbox 'app.js') -Encoding utf8
  & git add .env app.js 2>$null
} finally { Pop-Location }

Test-Cmd 'git commit -m "primer commit"'  2  $Sandbox  'el .env esta en el index'

# git rm --cached, no git restore --staged: el repo aun no tiene HEAD y
# restore --staged necesita uno.
Push-Location $Sandbox
try { & git rm --cached -q .env 2>$null } finally { Pop-Location }
Test-Cmd 'git commit -m "primer commit"'  0  $Sandbox  'ya sin el .env en el index'

Remove-Item $Sandbox -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Debe fallar abierto ==="
foreach ($p in @('no soy json', '', '{"tool_name":"Read","tool_input":{"file_path":"x"}}')) {
  $p | & powershell -NoProfile -ExecutionPolicy Bypass -File $HookPath 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Host "  PASS  deja pasar entrada rara" }
  else { Write-Host "  FAIL  entrada rara dio $LASTEXITCODE" -ForegroundColor Red; $fail++ }
}

Write-Host ""
Write-Host "=== El mensaje explica que hacer ==="
$json = '{"tool_name":"Bash","tool_input":{"command":"git add .env"}}'
$err = ($json | & powershell -NoProfile -ExecutionPolicy Bypass -File $HookPath 2>&1 | Out-String)
if ($err -match 'guard-secretos' -and $err -match 'gitignore' -and $err -match 'historial') {
  Write-Host "  PASS  stderr dice el motivo y la salida"
} else {
  Write-Host "  FAIL  stderr incompleto:`n$err" -ForegroundColor Red; $fail++
}

Write-Host ""
if ($fail -eq 0) { Write-Host "TODO OK (0 fallos)" -ForegroundColor Green }
else { Write-Host "$fail FALLOS" -ForegroundColor Red }
exit $fail
