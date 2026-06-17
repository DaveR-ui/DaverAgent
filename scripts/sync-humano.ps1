[CmdletBinding()]
param(
    [string]$TargetRoot = $(Join-Path $env:USERPROFILE ".config\opencode"),
    [string]$HumanId = $env:USERNAME
)

$ErrorActionPreference = "Stop"

$source = Join-Path $TargetRoot "humans\$HumanId\humano.md"
$target = Join-Path $TargetRoot "sessions\$HumanId\humano.md"

if (-not (Test-Path -LiteralPath $source)) {
    throw "Human source not found: $source"
}

$parent = Split-Path -Parent $target
if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

Copy-Item -LiteralPath $source -Destination $target -Force
"Synced $source -> $target"
