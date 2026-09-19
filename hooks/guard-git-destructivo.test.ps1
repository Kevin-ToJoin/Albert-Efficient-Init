<#
.SYNOPSIS
  Pruebas de guard-git-destructivo.ps1.

.DESCRIPTION
  Le mete al hook el mismo JSON que le manda Claude Code por stdin y comprueba
  el codigo de salida: 2 bloquea, 0 deja pasar.

  Un guard que bloquea de mas acaba desactivado, y entonces no protege nada.
  Por eso la mitad de los casos comprueban lo que NO debe tocar.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File hooks\guard-git-destructivo.test.ps1
#>
$HookPath = Join-Path $PSScriptRoot 'guard-git-destructivo.ps1'
$fail = 0

function Test-Cmd {
  param([string]$Command, [int]$Esperado, [string]$Nota)
  $payload = @{
    session_id      = 'test'
    hook_event_name = 'PreToolUse'
    tool_name       = 'Bash'
    tool_input      = @{ command = $Command }
  } | ConvertTo-Json -Depth 5 -Compress

  $payload | & powershell -NoProfile -ExecutionPolicy Bypass -File $HookPath 2>$null | Out-Null
  $code = $LASTEXITCODE

  $etiqueta = if ($Esperado -eq 2) { 'BLOQUEA' } else { 'permite' }
  if ($code -eq $Esperado) {
    Write-Host ("  PASS  {0,-7} {1}" -f $etiqueta, $Command)
  } else {
    Write-Host ("  FAIL  {0,-7} {1}  (esperaba {2}, dio {3}) {4}" -f $etiqueta, $Command, $Esperado, $code, $Nota) -ForegroundColor Red
    $script:fail++
  }
}

function Test-Stdin {
  param([string]$Payload, [string]$Nota)
  $Payload | & powershell -NoProfile -ExecutionPolicy Bypass -File $HookPath 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Host "  PASS  $Nota" }
  else { Write-Host "  FAIL  $Nota dio $LASTEXITCODE" -ForegroundColor Red; $script:fail++ }
}

Write-Host "=== Debe BLOQUEAR (exit 2) ==="
Test-Cmd 'git push --force origin main'        2
Test-Cmd 'git push -f'                          2
Test-Cmd 'git reset --hard HEAD~1'              2
Test-Cmd 'git clean -fd'                        2
Test-Cmd 'git clean -f'                         2
Test-Cmd 'git branch -D feature/algo'           2
Test-Cmd 'git status && git push --force'       2  'encadenado'
Test-Cmd 'cd /tmp; git reset --hard'            2  'encadenado con ;'

Write-Host ""
Write-Host "=== NO debe tocar (exit 0) ==="
Test-Cmd 'git push origin main'                 0
Test-Cmd 'git push --force-with-lease'          0  'la variante segura'
Test-Cmd 'git status'                           0
Test-Cmd 'git reset HEAD~1'                     0  'reset soft'
Test-Cmd 'git clean -n'                         0  'dry run'
Test-Cmd 'git branch -d feature/algo'           0  'minuscula: -d falla si hay huerfanos'
Test-Cmd 'npm run build -- -f'                  0  'tiene -f pero no es git push'
Test-Cmd 'git log --oneline'                    0

Write-Host ""
Write-Host "=== Debe fallar abierto (exit 0) ==="
Test-Stdin 'no soy json'                                            'permite JSON invalido'
Test-Stdin ''                                                       'permite stdin vacio'
Test-Stdin '{"tool_name":"Read","tool_input":{"file_path":"x"}}'    'permite un tool sin campo command'

Write-Host ""
Write-Host "=== El mensaje de bloqueo llega por stderr ==="
$json = '{"tool_name":"Bash","tool_input":{"command":"git push --force"}}'
$err = ($json | & powershell -NoProfile -ExecutionPolicy Bypass -File $HookPath 2>&1 | Out-String)
if ($err -match 'guard-git-destructivo' -and $err -match 'force-with-lease') {
  Write-Host "  PASS  stderr explica el motivo y la alternativa"
} else {
  Write-Host "  FAIL  stderr no trae el motivo esperado:`n$err" -ForegroundColor Red; $fail++
}

Write-Host ""
if ($fail -eq 0) { Write-Host "TODO OK (0 fallos)" -ForegroundColor Green }
else { Write-Host "$fail FALLOS" -ForegroundColor Red }
exit $fail
