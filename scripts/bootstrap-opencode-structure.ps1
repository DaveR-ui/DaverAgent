[CmdletBinding()]
param(
    [string]$TargetRoot = $(Join-Path $env:USERPROFILE ".config\opencode"),
    [string]$HumanId = $env:USERNAME,
    [string]$ProjectId,
    [string]$RepoPath,
    [switch]$VerifyOnly,
    [switch]$FailIfMissing,
    [switch]$RefreshDocumentation,
    [switch]$RefreshScripts,
    [switch]$RefreshTemplates
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not $ProjectId) {
    $ProjectId = Split-Path -Leaf $repoRoot
}
if (-not $RepoPath) {
    $RepoPath = $repoRoot
}

$templateSourceDir = Join-Path $repoRoot ".opencode\session-templates"
$scriptSourceDir = Join-Path $repoRoot ".opencode\scripts"

$created = New-Object System.Collections.Generic.List[string]
$updated = New-Object System.Collections.Generic.List[string]
$ok = New-Object System.Collections.Generic.List[string]
$missing = New-Object System.Collections.Generic.List[string]

function Add-Status {
    param(
        [System.Collections.Generic.List[string]]$Bucket,
        [string]$Value
    )
    $Bucket.Add($Value) | Out-Null
}

function Ensure-Directory {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Add-Status $ok "DIR  $Path"
        return
    }

    if ($VerifyOnly) {
        Add-Status $missing "DIR  $Path"
        return
    }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Add-Status $created "DIR  $Path"
}

function Write-FileIfNeeded {
    param(
        [string]$Path,
        [string]$Content,
        [switch]$Refresh
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        Ensure-Directory -Path $parent
    }

    if (Test-Path -LiteralPath $Path) {
        $current = Get-Content -LiteralPath $Path -Raw
        if ($current -eq $Content) {
            Add-Status $ok "FILE $Path"
            return
        }

        if (-not $Refresh) {
            Add-Status $ok "FILE $Path (kept existing)"
            return
        }

        if ($VerifyOnly) {
            Add-Status $missing "FILE $Path (would update)"
            return
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Add-Status $updated "FILE $Path"
        return
    }

    if ($VerifyOnly) {
        Add-Status $missing "FILE $Path"
        return
    }

    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    Add-Status $created "FILE $Path"
}

function Copy-FileIfNeeded {
    param(
        [string]$Source,
        [string]$Target,
        [switch]$Refresh
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Required source file not found: $Source"
    }

    $content = Get-Content -LiteralPath $Source -Raw
    Write-FileIfNeeded -Path $Target -Content $content -Refresh:$Refresh
}

function Expand-Template {
    param(
        [string]$TemplatePath,
        [hashtable]$Values
    )

    $content = Get-Content -LiteralPath $TemplatePath -Raw
    foreach ($key in $Values.Keys) {
        $content = $content.Replace(('{{' + $key + '}}'), [string]$Values[$key])
    }
    return $content
}

function New-RootReadme {
    return @"
# Opencode Home

This folder stores global opencode configuration plus human/project/session context files.

## Top-level purpose

| Path | Purpose |
|---|---|
| `opencode.jsonc` | Global opencode config |
| `humans/` | Master human profiles |
| `projects/` | Master project context snapshots |
| `sessions/` | Working snapshots and per-task session artifacts |

## Recommended flow

    # verify only
    & "$TargetRoot\sessions\_scripts\bootstrap-opencode-structure.ps1" -VerifyOnly

    # create/update missing structure
    & "$TargetRoot\sessions\_scripts\bootstrap-opencode-structure.ps1" -RefreshDocumentation -RefreshScripts -RefreshTemplates

See `sessions/README.md` for the snapshot/session rules.
"@
}

function New-HumansReadme {
    return @"
# humans/

This directory contains master human profile sources.

- Edit `humans/{human_id}/humano.md` here.
- Sync the session-facing copy afterward.
- Do not treat this directory as task-specific history.
"@
}

function New-ProjectsReadme {
    return @"
# projects/

This directory contains master project context sources.

- Each `project.md` here is the source for session snapshots.
    - Prefer copying from the repo's project entry point (see `.opencode/conventions.md`) and adding review metadata.
- Keep task-specific notes out of this directory.
"@
}

function New-SessionsReadme {
    return @"
# sessions/

This directory contains working snapshots and per-task session artifacts.

## Meaning of each area

| Path | Purpose |
|---|---|
| `_scripts/` | bootstrap/sync/create-session helpers |
| `_templates/` | templates used by helpers |
| `{human_id}/humano.md` | snapshot copy of the human source |
| `{human_id}/{project_id}/project.md` | condensed snapshot copy of the project source |
| `{human_id}/{project_id}/{session_id}/` | per-task work folder |

## Rules

- `humans/` and `projects/` are sources.
- `sessions/` contains snapshots and work artifacts.
- Session folders should use `DDMMYYYY-keywords` naming.
- Use the bootstrap script if the base structure is missing.
"@
}

$paths = @(
    $TargetRoot,
    (Join-Path $TargetRoot "humans"),
    (Join-Path $TargetRoot "humans\$HumanId"),
    (Join-Path $TargetRoot "projects"),
    (Join-Path $TargetRoot "projects\$ProjectId"),
    (Join-Path $TargetRoot "sessions"),
    (Join-Path $TargetRoot "sessions\_scripts"),
    (Join-Path $TargetRoot "sessions\_templates"),
    (Join-Path $TargetRoot "sessions\$HumanId"),
    (Join-Path $TargetRoot "sessions\$HumanId\$ProjectId")
)

foreach ($path in $paths) {
    Ensure-Directory -Path $path
}

Write-FileIfNeeded -Path (Join-Path $TargetRoot "README.md") -Content (New-RootReadme) -Refresh:$RefreshDocumentation
Write-FileIfNeeded -Path (Join-Path $TargetRoot "humans\README.md") -Content (New-HumansReadme) -Refresh:$RefreshDocumentation
Write-FileIfNeeded -Path (Join-Path $TargetRoot "projects\README.md") -Content (New-ProjectsReadme) -Refresh:$RefreshDocumentation
Write-FileIfNeeded -Path (Join-Path $TargetRoot "sessions\README.md") -Content (New-SessionsReadme) -Refresh:$RefreshDocumentation

$templateTargets = @{
    "humano-template.md" = "humano-template.md"
    "project-source-template.md" = "project-source-template.md"
    "project-session-template.md" = "project-session-template.md"
    "general-context-template.md" = "general-context-template.md"
    "project-template.md" = "project-session-template.md"
}

foreach ($targetName in $templateTargets.Keys) {
    $sourceName = $templateTargets[$targetName]
    Copy-FileIfNeeded -Source (Join-Path $templateSourceDir $sourceName) -Target (Join-Path $TargetRoot "sessions\_templates\$targetName") -Refresh:$RefreshTemplates
}

$scriptNames = @(
    "bootstrap-opencode-structure.ps1",
    "init-sessions.ps1",
    "test-opencode-structure.ps1",
    "sync-humano.ps1",
    "sync-project.ps1",
    "new-session.ps1"
)

foreach ($scriptName in $scriptNames) {
    Copy-FileIfNeeded -Source (Join-Path $scriptSourceDir $scriptName) -Target (Join-Path $TargetRoot "sessions\_scripts\$scriptName") -Refresh:$RefreshScripts
}

$today = Get-Date -Format "yyyy-MM-dd"
$nextReview = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")

$humanoSource = Join-Path $TargetRoot "humans\$HumanId\humano.md"
$humanoTemplate = Join-Path $templateSourceDir "humano-template.md"
$humanoContent = Expand-Template -TemplatePath $humanoTemplate -Values @{
    HUMAN_ID = $HumanId
    HUMAN_NAME = "TODO: fill in name"
    LANGUAGE = "TODO: fill in language"
    OS_USERNAME = $env:USERNAME
    DETAIL_LEVEL = "summary"
    SHOW_THINKING = "false"
    SESSION_NAME_FORMAT = "DDMMYYYY-keywords"
    KEYWORDS_STYLE = "kebab-case"
    MAX_KEYWORDS = "2-4"
    SLANG_TERM_1 = ""
    STANDARD_MEANING_1 = ""
    ENGLISH_TRANSLATION_1 = ""
    CONTEXT_1 = ""
    TECH_TERM_1 = ""
    TECH_MEANING_1 = ""
    TECH_ENGLISH_1 = ""
    CONFIDENCE_1 = ""
}
Write-FileIfNeeded -Path $humanoSource -Content $humanoContent

$sessionHumano = Join-Path $TargetRoot "sessions\$HumanId\humano.md"
Write-FileIfNeeded -Path $sessionHumano -Content $humanoContent

$repoProjectMd = Join-Path $RepoPath "docs\project.md"
$projectSource = Join-Path $TargetRoot "projects\$ProjectId\project.md"
if (Test-Path -LiteralPath $repoProjectMd) {
    $repoProjectContent = Get-Content -LiteralPath $repoProjectMd -Raw
    $projectSourceContent = @"
# Project Context (Master Source)

> **ROLE**: master source file (mirrors repo's project entry point; see `.opencode/conventions.md`)
> **SOURCE REPO**: `$RepoPath/<project_entry_point>` (see `.opencode/conventions.md`)
> **LAST REVIEWED**: $today
> **NEXT REVIEW DUE**: $nextReview
> **REVIEW CADENCE**: monthly (~30 days)

> Auto-generated by `bootstrap-opencode-structure.ps1`. Do not edit directly.
> Edit the project entry point (see `.opencode/conventions.md`) in the repo and re-run bootstrap with `-RefreshDocumentation`.

$repoProjectContent
"@
    Write-FileIfNeeded -Path $projectSource -Content $projectSourceContent
} else {
    $projectSourceTemplate = Join-Path $templateSourceDir "project-source-template.md"
    $projectSourceContent = Expand-Template -TemplatePath $projectSourceTemplate -Values @{
        PROJECT_ID = $ProjectId
        PROJECT_REPO_PATH = $RepoPath
        LAST_REVIEWED = $today
        NEXT_REVIEW_DUE = $nextReview
        PROJECT_NAME = $ProjectId
        PROJECT_DESCRIPTION = "TODO: fill in description"
        TECH_STACK = "- TODO"
        ARCHITECTURE = "- TODO"
        COMMANDS = "- TODO"
        NOTES = "- Repo project entry point (see .opencode/conventions.md) not found during bootstrap"
    }
    Write-FileIfNeeded -Path $projectSource -Content $projectSourceContent
}

$projectSessionTemplate = Join-Path $templateSourceDir "project-session-template.md"
$projectSessionContent = Expand-Template -TemplatePath $projectSessionTemplate -Values @{
    PROJECT_ID = $ProjectId
    PROJECT_NAME = $ProjectId
    PROJECT_DESCRIPTION = "Condensed session snapshot. Review and edit as needed."
    LAST_REVIEWED = $today
    NEXT_REVIEW_DUE = $nextReview
    TECH_STACK_SUMMARY = "TODO"
    ARCH_SUMMARY = "TODO"
    SLANG_1 = ""
    MEANING_1 = ""
    LOCATION_1 = ""
    CONFIDENCE_1 = ""
    PROJECT_REPO_PATH = $RepoPath
}
Write-FileIfNeeded -Path (Join-Path $TargetRoot "sessions\$HumanId\$ProjectId\project.md") -Content $projectSessionContent

$result = [pscustomobject]@{
    TargetRoot = $TargetRoot
    VerifyOnly = [bool]$VerifyOnly
    Created = $created.ToArray()
    Updated = $updated.ToArray()
    Existing = $ok.ToArray()
    Missing = $missing.ToArray()
    MissingCount = $missing.Count
}

if ($VerifyOnly) {
    "VERIFY ONLY: $($missing.Count) missing or stale item(s)."
    foreach ($item in $missing) {
        "  MISSING $item"
    }
} else {
    "BOOTSTRAP COMPLETE"
    foreach ($item in $created) {
        "  CREATED $item"
    }
    foreach ($item in $updated) {
        "  UPDATED $item"
    }
}

$result

if ($VerifyOnly -and $FailIfMissing -and $missing.Count -gt 0) {
    exit 1
}
