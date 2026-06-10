# Create a new work session
param(
    [Parameter(Mandatory)]
    [string]$SessionName,
    [string]$HumanId = "david.romaniuk",
    [string]$ProjectId = "DFCustomerPortal_SPA_AIR226766"
)

$base = "$env:USERPROFILE\.config\opencode\sessions"
$sessionDir = "$base\$HumanId\$ProjectId\$SessionName"

if (Test-Path $sessionDir) {
    Write-Error "Session already exists: $sessionDir"
    exit 1
}

New-Item -ItemType Directory -Path "$sessionDir\assets" -Force | Out-Null

# Copy general-context template
$template = "$base\_templates\general-context-template.md"
if (Test-Path $template) {
    Copy-Item -Path $template -Destination "$sessionDir\general-context.md"
    Write-Host "Created general-context.md from template"
}

Write-Host "Session created: $sessionDir"
