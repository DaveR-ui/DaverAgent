# init-sessions.ps1
# Full bootstrap of the opencode sessions directory structure.
# Idempotent: safe to run multiple times, only creates what's missing.

param(
    [string]$HumanId = "david.romaniuk",
    [string]$ProjectId = "DFCustomerPortal_SPA_AIR226766",
    [string]$RepoPath = "C:\projects\DFCustomerPortal_SPA_AIR226766"
)

$ErrorActionPreference = "Stop"
$base = "$env:USERPROFILE\.config\opencode"
$created = @()
$skipped = @()

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        $script:created += "DIR  $Path"
    } else {
        $script:skipped += "DIR  $Path (exists)"
    }
}

function Ensure-File {
    param(
        [string]$Path,
        [scriptblock]$CreateAction
    )
    if (-not (Test-Path $Path)) {
        & $CreateAction
        $script:created += "FILE $Path"
    } else {
        $script:skipped += "FILE $Path (exists)"
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Opencode Sessions Bootstrap" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Human:   $HumanId"
Write-Host "Project: $ProjectId"
Write-Host "Repo:    $RepoPath"
Write-Host "Base:    $base"
Write-Host ""

# -------------------------------------------------------
# Step 1: Create base directories
# -------------------------------------------------------
Write-Host "[1/8] Creating base directories..." -ForegroundColor Yellow

Ensure-Directory "$base\humans"
Ensure-Directory "$base\humans\$HumanId"
Ensure-Directory "$base\projects"
Ensure-Directory "$base\projects\$ProjectId"
Ensure-Directory "$base\sessions"
Ensure-Directory "$base\sessions\_scripts"
Ensure-Directory "$base\sessions\_templates"
Ensure-Directory "$base\sessions\$HumanId"
Ensure-Directory "$base\sessions\$HumanId\$ProjectId"

# -------------------------------------------------------
# Step 2: Create humano.md source from template
# -------------------------------------------------------
Write-Host "[2/8] Checking humano.md source..." -ForegroundColor Yellow

$humanoSource = "$base\humans\$HumanId\humano.md"
$humanoTemplate = "$base\sessions\_templates\humano-template.md"

Ensure-File -Path $humanoSource -CreateAction {
    if (Test-Path $humanoTemplate) {
        $content = Get-Content -Path $humanoTemplate -Raw
        # Replace known variables with defaults
        $content = $content -replace '\{\{HUMAN_ID\}\}', $HumanId
        $content = $content -replace '\{\{OS_USERNAME\}\}', $env:USERNAME
        $content = $content -replace '\{\{HUMAN_NAME\}\}', 'TODO: Fill in name'
        $content = $content -replace '\{\{LANGUAGE\}\}', 'es-AR'
        $content = $content -replace '\{\{DETAIL_LEVEL\}\}', 'summary'
        $content = $content -replace '\{\{SHOW_THINKING\}\}', 'false'
        $content = $content -replace '\{\{SESSION_NAME_FORMAT\}\}', 'DDMMYYYY-keywords'
        $content = $content -replace '\{\{KEYWORDS_STYLE\}\}', 'kebab-case'
        $content = $content -replace '\{\{MAX_KEYWORDS\}\}', '2-4'
        $content = $content -replace '\{\{SLANG_COUNT\}\}', '0'
        $content = $content -replace '\{\{TECH_COUNT\}\}', '0'
        $content = $content -replace '\{\{SLANG_STATUS\}\}', 'OK'
        $content = $content -replace '\{\{TECH_STATUS\}\}', 'OK'
        $content = $content -replace '\{\{LAST_UPDATED\}\}', (Get-Date -Format 'yyyy-MM-dd')
        Set-Content -Path $humanoSource -Value $content -Encoding UTF8
    } else {
        # Create minimal placeholder if template not yet available
        @"
# Human Profile

## Identity
- **ID**: $HumanId
- **Name**: TODO: Fill in name
- **Language**: es-AR
- **OS Username**: $env:USERNAME

## Communication Preferences
- **Detail Level**: summary
- **Show Thinking**: false
- **Preferred Tone**: Neutral/Professional

## Session Naming Rules
- **Format**: DDMMYYYY-keywords
- **Keywords Style**: kebab-case
- **Max Keywords**: 2-4

## Translation Dictionary

> Add slang and technical terms as they are encountered.

### Slang/Colloquialisms -> Standard Translation

| Term | Standard Meaning | English Translation | Context/Notes |
|------|-----------------|---------------------|---------------|

### Technical Terms (Project-Specific)

| Term | Meaning | English Translation | Confidence |
|------|---------|---------------------|------------|
"@ | Set-Content -Path $humanoSource -Encoding UTF8
    }
}

# -------------------------------------------------------
# Step 3: Create project.md source from repo
# -------------------------------------------------------
Write-Host "[3/8] Checking project.md source..." -ForegroundColor Yellow

$projectSource = "$base\projects\$ProjectId\project.md"
$repoProjectMd = "$RepoPath\.opencode\project.md"

Ensure-File -Path $projectSource -CreateAction {
    if (Test-Path $repoProjectMd) {
        $repoContent = Get-Content -Path $repoProjectMd -Raw
        $today = Get-Date -Format 'yyyy-MM-dd'
        $nextReview = (Get-Date).AddDays(30).ToString('yyyy-MM-dd')
        $header = @"
# Project Context

> **SOURCE**: Copied from $RepoPath\.opencode\project.md
> **LAST REVIEWED**: $today
> **NEXT REVIEW DUE**: $nextReview
> **REVIEW CADENCE**: monthly (~30 days)

"@
        $content = $header + "`n" + $repoContent
        Set-Content -Path $projectSource -Value $content -Encoding UTF8
    } else {
        @"
# Project Context

> **SOURCE**: $RepoPath\.opencode\project.md (not found at bootstrap time)
> **LAST REVIEWED**: $(Get-Date -Format 'yyyy-MM-dd')
> **NEXT REVIEW DUE**: $((Get-Date).AddDays(30).ToString('yyyy-MM-dd'))
> **REVIEW CADENCE**: monthly (~30 days)

## Overview
- **Project Name**: $ProjectId
- **Project ID**: $ProjectId
- **Description**: TODO: Fill in description

## Technology Stack
- TODO: Fill in technology stack
"@ | Set-Content -Path $projectSource -Encoding UTF8
    }
}

# -------------------------------------------------------
# Step 4: Copy humano.md to sessions
# -------------------------------------------------------
Write-Host "[4/8] Syncing humano.md to sessions..." -ForegroundColor Yellow

$sessionsHumano = "$base\sessions\$HumanId\humano.md"
if (Test-Path $humanoSource) {
    Copy-Item -Path $humanoSource -Destination $sessionsHumano -Force
    $created += "FILE $sessionsHumano (synced from source)"
}

# -------------------------------------------------------
# Step 5: Create condensed project.md in sessions
# -------------------------------------------------------
Write-Host "[5/8] Checking sessions project.md..." -ForegroundColor Yellow

$sessionsProject = "$base\sessions\$HumanId\$ProjectId\project.md"

Ensure-File -Path $sessionsProject -CreateAction {
    $today = Get-Date -Format 'yyyy-MM-dd'
    $nextReview = (Get-Date).AddDays(30).ToString('yyyy-MM-dd')
    @"
# Project Context (Condensed)

> **LAST REVIEWED**: $today
> **NEXT REVIEW DUE**: $nextReview
> **REVIEW CADENCE**: monthly (~30 days)

## Overview
- **Project Name**: $ProjectId
- **Project ID**: $ProjectId
- **Description**: TODO: Condense from full project.md

## Technology Stack
- TODO: Single-line per category

## Architecture
- **Pattern**: TODO
- **Data Flow**: TODO
- **Structure**: TODO

## Project Slang (Inferred from Codebase)

> These terms are inferred from code comments, variable names, function names, and documentation.
> Confidence levels: High (consistent across files), Medium (few places), Low (once or ambiguous).

| Term | Meaning | Location | Confidence |
|------|---------|----------|------------|

## Key Skills
- TODO: List available skills

## Additional Notes
- Full project context: `~/.config/opencode/projects/$ProjectId/project.md`
- Repo project.md: `$RepoPath\.opencode\project.md`
"@ | Set-Content -Path $sessionsProject -Encoding UTF8
}

# -------------------------------------------------------
# Step 6: Copy templates
# -------------------------------------------------------
Write-Host "[6/8] Checking templates..." -ForegroundColor Yellow

$templatesDir = "$base\sessions\_templates"
$templateFiles = @("humano-template.md", "project-template.md", "general-context-template.md")

foreach ($tf in $templateFiles) {
    $targetPath = "$templatesDir\$tf"
    if (-not (Test-Path $targetPath)) {
        # Templates should already exist from initial setup; warn if missing
        $skipped += "WARN Template missing: $targetPath (create manually or re-run bootstrap)"
    } else {
        $skipped += "FILE $targetPath (exists)"
    }
}

# -------------------------------------------------------
# Step 7: Copy scripts
# -------------------------------------------------------
Write-Host "[7/8] Checking scripts..." -ForegroundColor Yellow

$scriptsDir = "$base\sessions\_scripts"
$scriptFiles = @("init-sessions.ps1", "sync-humano.ps1", "sync-project.ps1", "new-session.ps1")

foreach ($sf in $scriptFiles) {
    $targetPath = "$scriptsDir\$sf"
    if (-not (Test-Path $targetPath)) {
        if ($sf -eq "init-sessions.ps1") {
            # This script IS init-sessions.ps1; it should exist since we're running it
            $skipped += "WARN Script missing: $targetPath (copy manually)"
        } else {
            $skipped += "WARN Script missing: $targetPath (create manually or re-run bootstrap)"
        }
    } else {
        $skipped += "FILE $targetPath (exists)"
    }
}

# -------------------------------------------------------
# Step 8: Create README.md
# -------------------------------------------------------
Write-Host "[8/8] Checking README.md..." -ForegroundColor Yellow

$readmePath = "$base\sessions\README.md"
Ensure-File -Path $readmePath -CreateAction {
    @"
# Sessions System

> Session structure for the Delivery Agent: human-project-task context management.

## Quick Start

``````powershell
# Full bootstrap
& "`$env:USERPROFILE\.config\opencode\sessions\_scripts\init-sessions.ps1"

# Create new session
& "`$env:USERPROFILE\.config\opencode\sessions\_scripts\new-session.ps1" -SessionName "DDMMYYYY-keywords"

# Sync humano.md
& "`$env:USERPROFILE\.config\opencode\sessions\_scripts\sync-humano.ps1"

# Sync project.md
& "`$env:USERPROFILE\.config\opencode\sessions\_scripts\sync-project.ps1"
``````

## Directory Layout

``````
~/.config/opencode/
+-- humans/{human_id}/humano.md          # SOURCE (edit here)
+-- projects/{project_id}/project.md     # SOURCE (edit here)
+-- sessions/
    +-- _scripts/                        # PowerShell helpers
    +-- _templates/                      # File templates
    +-- {human_id}/
        +-- humano.md                    # COPY (synced from source)
        +-- {project_id}/
            +-- project.md               # CONDENSED copy
            +-- {DDMMYYYY-keywords}/     # Work session
                +-- general-context.md
                +-- enhanced-prompt.md
                +-- scope.md
                +-- assets/
``````

See the `sessions-setup` skill for full documentation.
"@ | Set-Content -Path $readmePath -Encoding UTF8
}

# -------------------------------------------------------
# Summary
# -------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Bootstrap Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($created.Count -gt 0) {
    Write-Host "Created ($($created.Count)):" -ForegroundColor Green
    foreach ($item in $created) {
        Write-Host "  + $item" -ForegroundColor Green
    }
} else {
    Write-Host "Nothing new created - everything already exists." -ForegroundColor DarkGray
}

if ($skipped.Count -gt 0) {
    Write-Host ""
    Write-Host "Skipped ($($skipped.Count)):" -ForegroundColor DarkGray
    foreach ($item in $skipped) {
        Write-Host "  - $item" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review and fill in: $base\humans\$HumanId\humano.md"
Write-Host "  2. Review and fill in: $base\projects\$ProjectId\project.md"
Write-Host "  3. Condense sessions project.md: $sessionsProject"
Write-Host "  4. Create first session: & `"$scriptsDir\new-session.ps1`" -SessionName `"$(Get-Date -Format 'ddMMyyyy')-first-session`""
Write-Host ""
