[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SessionName,
    [string]$TargetRoot = $(Join-Path $env:USERPROFILE ".config\opencode"),
    [string]$HumanId = $env:USERNAME,
    [string]$ProjectId,
    [string]$RepoPath
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($RepoPath) { $RepoPath } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path }
if (-not $ProjectId) {
    $ProjectId = Split-Path -Leaf $repoRoot
}

$bootstrap = Join-Path $PSScriptRoot "bootstrap-opencode-structure.ps1"
if (-not (Test-Path -LiteralPath (Join-Path $TargetRoot "sessions\_templates\general-context-template.md"))) {
    & $bootstrap -TargetRoot $TargetRoot -HumanId $HumanId -ProjectId $ProjectId -RepoPath $repoRoot | Out-Null
}

$sessionDir = Join-Path $TargetRoot "sessions\$HumanId\$ProjectId\$SessionName"
if (Test-Path -LiteralPath $sessionDir) {
    throw "Session already exists: $sessionDir"
}

New-Item -ItemType Directory -Path (Join-Path $sessionDir "assets") -Force | Out-Null

$template = Join-Path $TargetRoot "sessions\_templates\general-context-template.md"
$createdAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$content = (Get-Content -LiteralPath $template -Raw).
    Replace("{{SESSION_NAME}}", $SessionName).
    Replace("{{SESSION_ID}}", $SessionName).
    Replace("{{CREATED_AT}}", $createdAt).
    Replace("{{HUMAN_ID}}", $HumanId).
    Replace("{{PROJECT_ID}}", $ProjectId).
    Replace("{{PROMPT_LANGUAGE}}", "TODO").
    Replace("{{ORIGINAL_PROMPT}}", "TODO").
    Replace("{{PROMPT_TYPE}}", "TODO").
    Replace("{{PRIORITY}}", "TODO").
    Replace("{{COMPLEXITY}}", "TODO").
    Replace("{{ENHANCED_DESCRIPTION}}", "TODO").
    Replace("{{ATTACHMENT_1}}", "").
    Replace("{{TYPE_1}}", "").
    Replace("{{NOTES_1}}", "")

Set-Content -LiteralPath (Join-Path $sessionDir "general-context.md") -Value $content -Encoding UTF8
"Created session: $sessionDir"
