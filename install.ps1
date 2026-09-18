<#
.SYNOPSIS
  Albert-Efficient-Init installer (Windows / PowerShell).

.DESCRIPTION
  Instala dos cosas independientes:

    skills  ->  slash commands como /finalizar, usables en cualquier repo
    rules   ->  CLAUDE.md + Efficiency/ gitignoreados, por proyecto

  Idempotente: no sobrescribe archivos existentes salvo -Force, y no duplica
  entradas en .gitignore.

.PARAMETER Target
  Proyecto destino. Default: el directorio actual.

.PARAMETER SkillsOnly
  Instalar unicamente los slash commands.

.PARAMETER RulesOnly
  Instalar unicamente CLAUDE.md + Efficiency/.

.PARAMETER Scope
  'user'    -> ~/.claude/skills (default; disponible en todos los repos)
  'project' -> <Target>/.claude/skills (solo ese repo)

.PARAMETER Attach
  Escribe <Target>/.claude/settings.json registrando el marketplace y el plugin.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install.ps1 -SkillsOnly
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install.ps1 -Scope project -Attach
#>
[CmdletBinding()]
param(
  [string]$Target = (Get-Location).Path,
  [switch]$SkillsOnly,
  [switch]$RulesOnly,
  [ValidateSet('user', 'project')][string]$Scope = 'user',
  [switch]$Attach,
  [switch]$Force,
  [switch]$List
)

$ErrorActionPreference = 'Stop'

$ScriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcSkills       = Join-Path $ScriptDir 'plugins\albert\skills'
$MarketplaceName = 'albert-efficient'
$PluginName      = 'albert'
$RepoSlug        = 'Kevin-ToJoin/Albert-Efficient-Init'

if ($List) {
  Write-Host "Skills disponibles en ${SrcSkills}:"
  Get-ChildItem -Path $SrcSkills -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } |
    ForEach-Object { Write-Host "  /$($_.Name)" }
  exit 0
}

if (-not (Test-Path -PathType Container $Target)) {
  Write-Error "El directorio destino no existe: $Target"
}
$Target = (Resolve-Path $Target).Path

$doSkills = -not $RulesOnly
$doRules  = -not $SkillsOnly

function Copy-Tracked {
  param([string]$Src, [string]$Dest, [string]$Label)
  if ((Test-Path $Dest) -and (-not $Force)) {
    Write-Host "  skip   $Label (ya existe, usa -Force para sobrescribir)"
    return
  }
  $parent = Split-Path -Parent $Dest
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  Copy-Item -Path $Src -Destination $Dest -Force
  if ($Force) { Write-Host "  write  $Label" } else { Write-Host "  copy   $Label" }
}

function Install-Skills {
  if (-not (Test-Path -PathType Container $SrcSkills)) {
    Write-Error "No encuentro las skills en $SrcSkills"
  }

  $destRoot = if ($Scope -eq 'user') {
    Join-Path $HOME '.claude\skills'
  } else {
    Join-Path $Target '.claude\skills'
  }

  Write-Host "Slash commands -> $destRoot  (scope: $Scope)"

  $skillDirs = Get-ChildItem -Path $SrcSkills -Directory |
               Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }

  if (-not $skillDirs) { Write-Host '  (ninguna skill encontrada)'; Write-Host ''; return }

  foreach ($d in $skillDirs) {
    # Copia el directorio completo para que los archivos de apoyo viajen con SKILL.md.
    Get-ChildItem -Path $d.FullName -File -Recurse | ForEach-Object {
      $rel = $_.FullName.Substring($d.FullName.Length).TrimStart('\', '/')
      Copy-Tracked $_.FullName (Join-Path $destRoot (Join-Path $d.Name $rel)) "$($d.Name)/$rel"
    }
  }
  Write-Host ''
}

function Install-Rules {
  $srcEff = Join-Path $ScriptDir 'Efficiency'
  $srcTpl = Join-Path $ScriptDir 'CLAUDE-root-template.md'
  if (-not (Test-Path -PathType Container $srcEff)) { Write-Error "Falta $srcEff" }
  if (-not (Test-Path -PathType Leaf $srcTpl))      { Write-Error "Falta $srcTpl" }

  Write-Host "Reglas local-only -> $Target"

  $destEff = Join-Path $Target 'Efficiency'
  if (-not (Test-Path $destEff)) { New-Item -ItemType Directory -Path $destEff -Force | Out-Null }
  Get-ChildItem -Path $srcEff -Filter '*.md' -File | ForEach-Object {
    Copy-Tracked $_.FullName (Join-Path $destEff $_.Name) "Efficiency/$($_.Name)"
  }

  Copy-Tracked $srcTpl (Join-Path $Target 'CLAUDE.md') 'CLAUDE.md'

  $gitignore = Join-Path $Target '.gitignore'
  if (-not (Test-Path $gitignore)) { New-Item -ItemType File -Path $gitignore -Force | Out-Null }

  $lines = @(Get-Content -Path $gitignore -ErrorAction SilentlyContinue)
  $header = '# Albert-Efficient-Init (local-only rules)'
  if ($lines -notcontains $header) {
    Add-Content -Path $gitignore -Value ''
    Add-Content -Path $gitignore -Value $header
    $lines += $header
  }
  foreach ($entry in @('/CLAUDE.md', '/Efficiency/')) {
    if ($lines -contains $entry) {
      Write-Host "  skip   .gitignore $entry (ya presente)"
    } else {
      Add-Content -Path $gitignore -Value $entry
      Write-Host "  add    .gitignore $entry"
    }
  }
  Write-Host ''
}

function Set-JsonProperty {
  param($Object, [string]$Name, $Value)
  if ($Object.PSObject.Properties.Name -contains $Name) {
    $Object.$Name = $Value
  } else {
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
  }
}

function Add-Marketplace {
  $claudeDir = Join-Path $Target '.claude'
  $settings  = Join-Path $claudeDir 'settings.json'
  Write-Host "Marketplace -> $settings"

  if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }

  $data = [pscustomobject]@{}
  if (Test-Path $settings) {
    $text = (Get-Content -Path $settings -Raw)
    if ($text -and $text.Trim()) {
      try {
        $data = $text | ConvertFrom-Json
      } catch {
        Write-Error "$settings no es JSON valido; no lo toco. ($_)"
      }
    }
  }

  $markets = if ($data.PSObject.Properties.Name -contains 'extraKnownMarketplaces') {
    $data.extraKnownMarketplaces
  } else { [pscustomobject]@{} }
  Set-JsonProperty $markets $MarketplaceName ([pscustomobject]@{
    source = [pscustomobject]@{ source = 'github'; repo = $RepoSlug }
  })
  Set-JsonProperty $data 'extraKnownMarketplaces' $markets

  $plugins = if ($data.PSObject.Properties.Name -contains 'enabledPlugins') {
    $data.enabledPlugins
  } else { [pscustomobject]@{} }
  Set-JsonProperty $plugins "$PluginName@$MarketplaceName" $true
  Set-JsonProperty $data 'enabledPlugins' $plugins

  ($data | ConvertTo-Json -Depth 20) + "`n" | Set-Content -Path $settings -NoNewline -Encoding utf8
  Write-Host "  write  .claude/settings.json ($MarketplaceName + $PluginName@$MarketplaceName)"
  Write-Host ''
  Write-Host '  .claude/settings.json esta pensado para commitearse. Si prefieres que no'
  Write-Host '  viaje con el repo, usa settings.local.json o instala con -Scope user.'
  Write-Host ''
}

Write-Host 'Albert-Efficient-Init'
Write-Host "  origen:  $ScriptDir"
Write-Host "  destino: $Target"
Write-Host ''

if ($doSkills) { Install-Skills }
if ($doRules)  { Install-Rules }
if ($Attach)   { Add-Marketplace }

Write-Host 'Done.'
if ($doSkills) {
  Write-Host ''
  if ($Scope -eq 'user') {
    Write-Host 'Abre Claude Code en cualquier repo y escribe /finalizar.'
  } else {
    Write-Host "Abre Claude Code en $Target y escribe /finalizar."
  }
  Write-Host 'Si la sesion ya estaba abierta, corre /reload-plugins primero.'
}
