<#
.SYNOPSIS
  Prueba de extremo a extremo para install.ps1 / uninstall.ps1 (Windows).

.DESCRIPTION
  Corre los cuatro modos de enganche contra un HOME y unos targets falsos bajo
  Temp (con espacios en la ruta, como en un entorno real). No toca ~/.claude
  del usuario que ejecuta esto.

  $HOME es de solo lectura en el proceso actual de PowerShell 5.1, asi que
  install.ps1/uninstall.ps1 (que lo leen) se invocan en procesos hijo nuevos
  con $env:USERPROFILE apuntando al home falso.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tests\install_test.ps1
#>
$fail = 0
function Assert-True {
  param([bool]$Cond, [string]$Msg)
  if ($Cond) { Write-Host "  PASS  $Msg" }
  else { Write-Host "  FAIL  $Msg" -ForegroundColor Red; $script:fail++ }
}

$RepoDir = Split-Path -Parent $PSScriptRoot
$Sandbox = Join-Path $env:TEMP 'aei-ps-test sandbox'
if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Path $Sandbox -Force | Out-Null

$FakeHome = Join-Path $Sandbox 'fake home'
$Target1  = Join-Path $Sandbox 'project one'
$Target2  = Join-Path $Sandbox 'project two'
New-Item -ItemType Directory -Path $FakeHome, $Target1, $Target2 -Force | Out-Null

# Pre-seed target2 con un settings.json que tiene otras claves, para probar el merge.
New-Item -ItemType Directory -Path (Join-Path $Target2 '.claude') -Force | Out-Null
'{"foo": "bar", "permissions": {"allow": ["Bash(ls)"]}}' |
  Set-Content -Path (Join-Path $Target2 '.claude\settings.json') -NoNewline -Encoding utf8

$env:USERPROFILE = $FakeHome
$InstallPs1   = Join-Path $RepoDir 'install.ps1'
$UninstallPs1 = Join-Path $RepoDir 'uninstall.ps1'

function Invoke-Aei {
  param([string]$Script, [string[]]$ScriptArgs = @())
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script @ScriptArgs 2>&1
  $script:LastAeiExit = $LASTEXITCODE
  return ($out -join "`n")
}

Write-Host "=== 1) install.ps1 -List ==="
$out = Invoke-Aei $InstallPs1 @('-List')
Assert-True ($out -match '/finalizar') "-List muestra /finalizar"
Assert-True ($LastAeiExit -eq 0) "-List sale con exit 0"

Write-Host "`n=== 2) install default (skills user-scope + rules) sobre Target1 ==="
Invoke-Aei $InstallPs1 @('-Target', $Target1) | Out-Null
Assert-True ($LastAeiExit -eq 0) "install default sale con exit 0"
$skillFile = Join-Path $FakeHome '.claude\skills\finalizar\SKILL.md'
Assert-True (Test-Path $skillFile) "skill copiada a HOME fake"
Assert-True (Test-Path (Join-Path $Target1 'CLAUDE.md')) "CLAUDE.md copiado a Target1"
Assert-True (Test-Path (Join-Path $Target1 'Efficiency\rules-coding.md')) "Efficiency/rules-coding.md copiado"
$gi1 = Get-Content (Join-Path $Target1 '.gitignore') -Raw
Assert-True ($gi1 -match [regex]::Escape('/CLAUDE.md')) ".gitignore tiene /CLAUDE.md"
Assert-True ($gi1 -match [regex]::Escape('/Efficiency/')) ".gitignore tiene /Efficiency/"

Write-Host "`n=== 3) re-run idempotente (sin -Force) ==="
$out2 = Invoke-Aei $InstallPs1 @('-Target', $Target1)
Assert-True ($out2 -match 'skip\s+CLAUDE\.md') "segunda corrida hace skip de CLAUDE.md"
$giCountBefore = (Get-Content (Join-Path $Target1 '.gitignore') | Where-Object { $_ -eq '/CLAUDE.md' }).Count
Assert-True ($giCountBefore -eq 1) ".gitignore no duplica /CLAUDE.md tras 2 corridas"

Write-Host "`n=== 4) -Force sobreescribe ==="
Set-Content -Path (Join-Path $Target1 'CLAUDE.md') -Value 'MODIFICADO A MANO'
$out3 = Invoke-Aei $InstallPs1 @('-Target', $Target1, '-Force')
Assert-True ($out3 -match 'write\s+CLAUDE\.md') "-Force reporta 'write' para CLAUDE.md"
$content = Get-Content (Join-Path $Target1 'CLAUDE.md') -Raw
Assert-True ($content -notmatch 'MODIFICADO A MANO') "-Force realmente sobreescribio el contenido"

Write-Host "`n=== 5) -Scope project -Attach sobre Target2 (con settings.json preexistente) ==="
Invoke-Aei $InstallPs1 @('-Target', $Target2, '-Scope', 'project', '-Attach') | Out-Null
Assert-True ($LastAeiExit -eq 0) "attach sale con exit 0"
$skillProj = Join-Path $Target2 '.claude\skills\finalizar\SKILL.md'
Assert-True (Test-Path $skillProj) "skill copiada a Target2\.claude\skills (scope project)"
$settingsPath = Join-Path $Target2 '.claude\settings.json'
$json = Get-Content $settingsPath -Raw | ConvertFrom-Json
Assert-True ($json.foo -eq 'bar') "attach preserva clave 'foo' preexistente"
Assert-True ($json.permissions.allow -contains 'Bash(ls)') "attach preserva permissions.allow preexistente"
Assert-True ($json.extraKnownMarketplaces.'albert-efficient'.source.repo -eq 'Kevin-ToJoin/Albert-Efficient-Init') "attach agrego extraKnownMarketplaces.albert-efficient"
Assert-True ($json.enabledPlugins.'albert@albert-efficient' -eq $true) "attach agrego enabledPlugins.albert@albert-efficient=true"

Write-Host "`n=== 6) attach idempotente (re-run) ==="
Invoke-Aei $InstallPs1 @('-Target', $Target2, '-Scope', 'project', '-Attach') | Out-Null
$json2 = Get-Content $settingsPath -Raw | ConvertFrom-Json
Assert-True ($json2.foo -eq 'bar') "segundo attach sigue preservando 'foo'"

Write-Host "`n=== 7) uninstall default sobre Target1 (user scope) ==="
Invoke-Aei $UninstallPs1 @('-Target', $Target1) | Out-Null
Assert-True ($LastAeiExit -eq 0) "uninstall default sale con exit 0"
Assert-True (-not (Test-Path $skillFile)) "skill removida de HOME fake"
Assert-True (-not (Test-Path (Join-Path $Target1 'CLAUDE.md'))) "CLAUDE.md removido de Target1"
Assert-True (-not (Test-Path (Join-Path $Target1 'Efficiency'))) "Efficiency/ removido de Target1"
$giAfter = Get-Content (Join-Path $Target1 '.gitignore') -Raw -ErrorAction SilentlyContinue
Assert-True ($null -eq $giAfter -or $giAfter -notmatch [regex]::Escape('/CLAUDE.md')) ".gitignore limpio de /CLAUDE.md"
Assert-True (-not (Test-Path (Join-Path $FakeHome '.claude\skills'))) "dir 'skills' vacio en HOME se borra (paridad con rmdir de bash)"

Write-Host "`n=== 8) uninstall -Scope project -Detach sobre Target2 ==="
Invoke-Aei $UninstallPs1 @('-Target', $Target2, '-Scope', 'project', '-Detach') | Out-Null
Assert-True (-not (Test-Path $skillProj)) "skill removida de Target2 (scope project)"
$json3 = Get-Content $settingsPath -Raw | ConvertFrom-Json
Assert-True ($json3.foo -eq 'bar') "detach preserva 'foo' tras quitar marketplace"
Assert-True (-not ($json3.PSObject.Properties.Name -contains 'extraKnownMarketplaces')) "detach quito extraKnownMarketplaces"
Assert-True (-not ($json3.PSObject.Properties.Name -contains 'enabledPlugins')) "detach quito enabledPlugins"

Write-Host "`n=== 9) detach idempotente (re-run) ==="
$out4 = Invoke-Aei $UninstallPs1 @('-Target', $Target2, '-Scope', 'project', '-Detach')
Assert-True ($out4 -match 'skip\s+nada que quitar') "segundo detach dice 'nada que quitar'"

Write-Host "`n=== 10) settings.json invalido no se toca ==="
$Target3 = Join-Path $Sandbox 'project three'
New-Item -ItemType Directory -Path (Join-Path $Target3 '.claude') -Force | Out-Null
'{ esto no es json valido' | Set-Content -Path (Join-Path $Target3 '.claude\settings.json') -NoNewline -Encoding utf8
Invoke-Aei $InstallPs1 @('-Target', $Target3, '-Scope', 'project', '-Attach') | Out-Null
Assert-True ($LastAeiExit -ne 0) "install -Attach sobre JSON invalido sale con codigo != 0"
$stillBad = Get-Content (Join-Path $Target3 '.claude\settings.json') -Raw
Assert-True ($stillBad -eq '{ esto no es json valido') "settings.json invalido queda intacto (no lo pisa)"

Remove-Item $Sandbox -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n================================"
if ($fail -eq 0) { Write-Host "TODO OK (0 fallos)" -ForegroundColor Green }
else { Write-Host "$fail FALLOS" -ForegroundColor Red }
exit $fail
