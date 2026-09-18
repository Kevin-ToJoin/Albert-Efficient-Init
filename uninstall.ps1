<#
.SYNOPSIS
  Albert-Efficient-Init uninstaller (Windows / PowerShell).

.DESCRIPTION
  Quita los slash commands instalados por este repo, los archivos de reglas
  local-only, y opcionalmente el marketplace del settings.json del proyecto.

  Solo borra las skills que este repo instala. Nunca toca otras skills tuyas.

.PARAMETER Target
  Proyecto destino. Default: el directorio actual.

.PARAMETER SkillsOnly
  Quitar unicamente los slash commands.

.PARAMETER RulesOnly
  Quitar unicamente CLAUDE.md + Efficiency/.

.PARAMETER Scope
  'user' -> ~/.claude/skills (default). 'project' -> <Target>/.claude/skills.

.PARAMETER Detach
  Quitar el marketplace y el plugin de <Target>/.claude/settings.json.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File uninstall.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File uninstall.ps1 -Detach
#>
[CmdletBinding()]
param(
  [string]$Target = (Get-Location).Path,
  [switch]$SkillsOnly,
  [switch]$RulesOnly,
  [ValidateSet('user', 'project')][string]$Scope = 'user',
  [switch]$Detach
)

$ErrorActionPreference = 'Stop'

$ScriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcSkills       = Join-Path $ScriptDir 'plugins\albert\skills'
$MarketplaceName = 'albert-efficient'
$PluginName      = 'albert'

if (-not (Test-Path -PathType Container $Target)) {
  Write-Error "El directorio destino no existe: $Target"
}
$Target = (Resolve-Path $Target).Path

$doSkills = -not $RulesOnly
$doRules  = -not $SkillsOnly

Write-Host 'Albert-Efficient-Init uninstall'
Write-Host "  destino: $Target"
Write-Host ''

function Remove-Skills {
  $destRoot = if ($Scope -eq 'user') {
    Join-Path $HOME '.claude\skills'
  } else {
    Join-Path $Target '.claude\skills'
  }
  Write-Host "Slash commands <- $destRoot"

  if (-not (Test-Path -PathType Container $SrcSkills)) {
    Write-Error "No encuentro $SrcSkills, no se que quitar"
  }

  Get-ChildItem -Path $SrcSkills -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } |
    ForEach-Object {
      $d = Join-Path $destRoot $_.Name
      if (Test-Path $d) {
        Remove-Item -Path $d -Recurse -Force
        Write-Host "  rm     $($_.Name)/"
      } else {
        Write-Host "  skip   $($_.Name)/ (no estaba)"
      }
    }
  Write-Host ''
}

function Remove-Rules {
  Write-Host "Reglas local-only <- $Target"

  $claudeMd = Join-Path $Target 'CLAUDE.md'
  if (Test-Path $claudeMd) {
    Remove-Item -Path $claudeMd -Force; Write-Host '  rm     CLAUDE.md'
  } else { Write-Host '  skip   CLAUDE.md (no estaba)' }

  $eff = Join-Path $Target 'Efficiency'
  if (Test-Path $eff) {
    Remove-Item -Path $eff -Recurse -Force; Write-Host '  rm     Efficiency/'
  } else { Write-Host '  skip   Efficiency/ (no estaba)' }

  $gitignore = Join-Path $Target '.gitignore'
  if (Test-Path $gitignore) {
    $drop = @('# Albert-Efficient-Init (local-only rules)', '/CLAUDE.md', '/Efficiency/')
    $kept = @(Get-Content -Path $gitignore) | Where-Object { $drop -notcontains $_ }
    # Colapsa las lineas en blanco repetidas que deja el bloque removido.
    $out = New-Object System.Collections.Generic.List[string]
    $pending = $false
    foreach ($line in $kept) {
      if ([string]::IsNullOrWhiteSpace($line)) { $pending = $true; continue }
      if ($pending -and $out.Count -gt 0) { $out.Add('') }
      $pending = $false
      $out.Add($line)
    }
    Set-Content -Path $gitignore -Value $out -Encoding utf8
    Write-Host '  clean  .gitignore'
  }
  Write-Host ''
}

function Remove-Marketplace {
  $settings = Join-Path $Target '.claude\settings.json'
  Write-Host "Marketplace <- $settings"
  if (-not (Test-Path $settings)) { Write-Host '  skip   no existe'; Write-Host ''; return }

  $text = (Get-Content -Path $settings -Raw)
  if (-not $text -or -not $text.Trim()) { Write-Host '  skip   settings.json vacio'; Write-Host ''; return }
  try { $data = $text | ConvertFrom-Json } catch {
    Write-Error "$settings no es JSON valido; no lo toco. ($_)"
  }

  $changed = @()
  $key = "$PluginName@$MarketplaceName"

  if ($data.PSObject.Properties.Name -contains 'extraKnownMarketplaces') {
    $m = $data.extraKnownMarketplaces
    if ($m.PSObject.Properties.Name -contains $MarketplaceName) {
      $m.PSObject.Properties.Remove($MarketplaceName)
      $changed += "extraKnownMarketplaces.$MarketplaceName"
      if ($m.PSObject.Properties.Name.Count -eq 0) {
        $data.PSObject.Properties.Remove('extraKnownMarketplaces')
      }
    }
  }

  if ($data.PSObject.Properties.Name -contains 'enabledPlugins') {
    $p = $data.enabledPlugins
    if ($p.PSObject.Properties.Name -contains $key) {
      $p.PSObject.Properties.Remove($key)
      $changed += "enabledPlugins.$key"
      if ($p.PSObject.Properties.Name.Count -eq 0) {
        $data.PSObject.Properties.Remove('enabledPlugins')
      }
    }
  }

  if ($changed.Count -eq 0) { Write-Host '  skip   nada que quitar'; Write-Host ''; return }

  ($data | ConvertTo-Json -Depth 20) + "`n" | Set-Content -Path $settings -NoNewline -Encoding utf8
  Write-Host "  rm     $($changed -join ', ')"
  Write-Host ''
}

if ($doSkills) { Remove-Skills }
if ($doRules)  { Remove-Rules }
if ($Detach)   { Remove-Marketplace }

Write-Host 'Done.'
