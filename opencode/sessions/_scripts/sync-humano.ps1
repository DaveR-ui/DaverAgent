# Sync humano.md from source to all session copies
param(
    [string]$HumanId = "david.romaniuk"
)

$base = "$env:USERPROFILE\.config\opencode"
$source = "$base\humans\$HumanId\humano.md"
$sessionsDir = "$base\sessions\$HumanId"

if (-not (Test-Path $source)) {
    Write-Error "Source file not found: $source"
    exit 1
}

if (-not (Test-Path $sessionsDir)) {
    Write-Host "No sessions directory found for $HumanId"
    exit 0
}

$target = "$sessionsDir\humano.md"
Copy-Item -Path $source -Destination $target -Force
Write-Host "Synced humano.md for $HumanId"
