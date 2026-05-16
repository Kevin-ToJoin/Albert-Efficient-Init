# Albert-Efficient-Init uninstaller (PowerShell)
#
# Removes the local rule files and strips the matching block from the target
# project .gitignore.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
#   powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -Target C:\path\to\project
#
# Idempotent: re-running is safe even if some pieces are already absent.

[CmdletBinding()]
param(
    [string]$Target = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    Write-Error "ERROR: target directory does not exist: $Target"
    exit 1
}

Write-Host "Uninstalling Albert-Efficient-Init from: $Target"
Write-Host ""

# 1. Remove CLAUDE.md.
$Claude = Join-Path $Target 'CLAUDE.md'
if (Test-Path -LiteralPath $Claude -PathType Leaf) {
    Remove-Item -LiteralPath $Claude -Force
    Write-Host "  remove CLAUDE.md"
} else {
    Write-Host "  skip   CLAUDE.md (not present)"
}

# 2. Remove Efficiency/.
$Eff = Join-Path $Target 'Efficiency'
if (Test-Path -LiteralPath $Eff -PathType Container) {
    Remove-Item -LiteralPath $Eff -Recurse -Force
    Write-Host "  remove Efficiency/"
} else {
    Write-Host "  skip   Efficiency/ (not present)"
}

# 3. Strip the .gitignore block.
$Gitignore = Join-Path $Target '.gitignore'
if (Test-Path -LiteralPath $Gitignore -PathType Leaf) {
    $lines = Get-Content -LiteralPath $Gitignore
    $kept = $lines | Where-Object {
        ($_ -notmatch '^# Albert-Efficient-Init') -and
        ($_ -ne '/CLAUDE.md') -and
        ($_ -ne '/Efficiency/')
    }

    # Collapse trailing blank lines.
    $kept = @($kept)
    while ($kept.Count -gt 0 -and [string]::IsNullOrWhiteSpace($kept[-1])) {
        $kept = $kept[0..($kept.Count - 2)]
    }

    Set-Content -LiteralPath $Gitignore -Value $kept -Encoding utf8
    Write-Host "  clean  .gitignore"
} else {
    Write-Host "  skip   .gitignore (not present)"
}

Write-Host ""
Write-Host "Done."
