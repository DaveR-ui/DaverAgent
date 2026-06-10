# Sync project.md from source + repo to session copy
param(
    [string]$HumanId = "david.romaniuk",
    [string]$ProjectId = "DFCustomerPortal_SPA_AIR226766",
    [string]$RepoPath = "C:\projects\DFCustomerPortal_SPA_AIR226766"
)

$base = "$env:USERPROFILE\.config\opencode"
$source = "$base\projects\$ProjectId\project.md"
$repoSource = "$RepoPath\.opencode\project.md"
$target = "$base\sessions\$HumanId\$ProjectId\project.md"

if (-not (Test-Path $source)) {
    Write-Error "Source file not found: $source"
    exit 1
}

if (-not (Test-Path $repoSource)) {
    Write-Error "Repo project.md not found: $repoSource"
    exit 1
}

# For now, copy source as-is. The condensed version is maintained manually.
Copy-Item -Path $source -Destination $target -Force
Write-Host "Synced project.md for $ProjectId"
