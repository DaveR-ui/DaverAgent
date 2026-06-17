[CmdletBinding()]
param(
    [string]$TargetRoot = $(Join-Path $env:USERPROFILE ".config\opencode"),
    [string]$HumanId = $env:USERNAME,
    [string]$ProjectId,
    [string]$RepoPath,
    [switch]$RefreshSessionSnapshot
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($RepoPath) { $RepoPath } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path }
if (-not $ProjectId) {
    $ProjectId = Split-Path -Leaf $repoRoot
}

$repoProject = Join-Path $repoRoot ".opencode\project.md"
$source = Join-Path $TargetRoot "projects\$ProjectId\project.md"
$sessionProject = Join-Path $TargetRoot "sessions\$HumanId\$ProjectId\project.md"
$template = Join-Path $TargetRoot "sessions\_templates\project-session-template.md"

if (-not (Test-Path -LiteralPath $repoProject)) {
    throw "Repo project file not found: $repoProject"
}

$today = Get-Date -Format "yyyy-MM-dd"
$nextReview = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
$repoProjectContent = Get-Content -LiteralPath $repoProject -Raw
$sourceContent = @"
# Project Context

> **ROLE**: master source file
> **SOURCE REPO**: `$repoRoot/.opencode/project.md`
> **LAST REVIEWED**: $today
> **NEXT REVIEW DUE**: $nextReview
> **REVIEW CADENCE**: monthly (~30 days)

$repoProjectContent
"@

$sourceParent = Split-Path -Parent $source
if (-not (Test-Path -LiteralPath $sourceParent)) {
    New-Item -ItemType Directory -Path $sourceParent -Force | Out-Null
}
Set-Content -LiteralPath $source -Value $sourceContent -Encoding UTF8

if ((-not (Test-Path -LiteralPath $sessionProject)) -or $RefreshSessionSnapshot) {
    if (-not (Test-Path -LiteralPath $template)) {
        throw "Session template not found: $template"
    }

    $sessionParent = Split-Path -Parent $sessionProject
    if (-not (Test-Path -LiteralPath $sessionParent)) {
        New-Item -ItemType Directory -Path $sessionParent -Force | Out-Null
    }

    $sessionContent = (Get-Content -LiteralPath $template -Raw).
        Replace("{{PROJECT_ID}}", $ProjectId).
        Replace("{{PROJECT_NAME}}", $ProjectId).
        Replace("{{PROJECT_DESCRIPTION}}", "Condensed session snapshot. Review and edit as needed.").
        Replace("{{LAST_REVIEWED}}", $today).
        Replace("{{NEXT_REVIEW_DUE}}", $nextReview).
        Replace("{{TECH_STACK_SUMMARY}}", "TODO").
        Replace("{{ARCH_SUMMARY}}", "TODO").
        Replace("{{SLANG_1}}", "").
        Replace("{{MEANING_1}}", "").
        Replace("{{LOCATION_1}}", "").
        Replace("{{CONFIDENCE_1}}", "").
        Replace("{{PROJECT_REPO_PATH}}", $repoRoot)

    Set-Content -LiteralPath $sessionProject -Value $sessionContent -Encoding UTF8
    "Updated source and refreshed session snapshot"
} else {
    "Updated source only; existing session snapshot kept"
}
