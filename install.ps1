# Albert-Efficient-Init installer (PowerShell)
#
# Copies the rule files into a target project, wires up the root CLAUDE.md
# entry point, and adds both paths to the target project .gitignore.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target C:\path\to\project
#
# Idempotent: re-running preserves existing CLAUDE.md and does not duplicate
# .gitignore entries.

[CmdletBinding()]
param(
    [string]$Target = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    Write-Error "ERROR: target directory does not exist: $Target"
    exit 1
}

$SourceEfficiency = Join-Path $ScriptDir 'Efficiency'
$SourceTemplate   = Join-Path $ScriptDir 'CLAUDE-root-template.md'

if (-not (Test-Path -LiteralPath $SourceEfficiency -PathType Container)) {
    Write-Error "ERROR: source Efficiency/ folder missing at $SourceEfficiency"
    exit 1
}

if (-not (Test-Path -LiteralPath $SourceTemplate -PathType Leaf)) {
    Write-Error "ERROR: source CLAUDE-root-template.md missing at $ScriptDir"
    exit 1
}

Write-Host "Installing Albert-Efficient-Init into: $Target"
Write-Host ""

# 1. Copy Efficiency/ folder. Do not overwrite existing files.
$DestEfficiency = Join-Path $Target 'Efficiency'
if (-not (Test-Path -LiteralPath $DestEfficiency -PathType Container)) {
    New-Item -ItemType Directory -Path $DestEfficiency | Out-Null
}

Get-ChildItem -LiteralPath $SourceEfficiency -Filter '*.md' -File | ForEach-Object {
    $dest = Join-Path $DestEfficiency $_.Name
    if (Test-Path -LiteralPath $dest) {
        Write-Host "  skip   Efficiency/$($_.Name) (already present)"
    } else {
        Copy-Item -LiteralPath $_.FullName -Destination $dest
        Write-Host "  copy   Efficiency/$($_.Name)"
    }
}

# 2. Root CLAUDE.md. Only create if absent.
$DestClaude = Join-Path $Target 'CLAUDE.md'
if (Test-Path -LiteralPath $DestClaude) {
    Write-Host "  skip   CLAUDE.md (already present)"
} else {
    Copy-Item -LiteralPath $SourceTemplate -Destination $DestClaude
    Write-Host "  copy   CLAUDE.md"
}

# 3. Append to .gitignore (idempotent).
$Gitignore = Join-Path $Target '.gitignore'
if (-not (Test-Path -LiteralPath $Gitignore)) {
    New-Item -ItemType File -Path $Gitignore | Out-Null
}

# Read existing lines (handles BOM/CRLF transparently).
$existing = @()
if ((Get-Item -LiteralPath $Gitignore).Length -gt 0) {
    $existing = Get-Content -LiteralPath $Gitignore
}

$toAppend = New-Object System.Collections.Generic.List[string]

if (-not ($existing | Where-Object { $_ -like '*# Albert-Efficient-Init*' })) {
    if ($existing.Count -gt 0 -and $existing[-1].Trim() -ne '') {
        $toAppend.Add('')
    }
    $toAppend.Add('# Albert-Efficient-Init (local-only rules)')
}

function Add-IgnoreEntry($entry) {
    if (($existing -contains $entry) -or ($toAppend -contains $entry)) {
        Write-Host "  skip   .gitignore entry $entry (already present)"
    } else {
        $toAppend.Add($entry)
        Write-Host "  add    .gitignore entry $entry"
    }
}

Add-IgnoreEntry '/CLAUDE.md'
Add-IgnoreEntry '/Efficiency/'

if ($toAppend.Count -gt 0) {
    Add-Content -LiteralPath $Gitignore -Value $toAppend -Encoding utf8
}

Write-Host ""
Write-Host "Done."
Write-Host ""
Write-Host "Open the project in Claude Code. CLAUDE.md is now wired up and"
Write-Host "the local rule files are excluded from the project's git history."
