[CmdletBinding()]
param(
    [string]$RepoPath = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
    [switch]$NonInteractive,
    [string]$AnswersFile,
    [switch]$WhatIf,
    [switch]$VerifyOnly,
    [switch]$Update,
    [string]$BackupDir
)

$ErrorActionPreference = "Stop"
$script:RepoRoot = $RepoPath
$script:Schema = $null
$script:Answers = @{}
$script:Created = New-Object System.Collections.Generic.List[string]
$script:Updated = New-Object System.Collections.Generic.List[string]
$script:Skipped = New-Object System.Collections.Generic.List[string]
$script:Backups = New-Object System.Collections.Generic.List[string]
$script:BackupRoot = $null

# --- schema ----------------------------------------------------------------

function Read-Schema {
    $schemaPath = Join-Path $PSScriptRoot "install-agent.schema.json"
    if (-not (Test-Path -LiteralPath $schemaPath)) {
        throw "Schema not found: $schemaPath"
    }
    return Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json
}

# --- questions -------------------------------------------------------------

function Ask-Question {
    param(
        [string]$Prompt,
        [string]$Default = "",
        [string[]]$Options,
        [switch]$IsMultiline,
        [switch]$IsBool
    )

    if ($IsBool) {
        $yn = if ($Default -eq "true") { "Y/n" } else { "y/N" }
        $suffix = " [$yn]"
    }
    elseif ($Options -and $Options.Count -gt 0) {
        $suffix = " [$($Options -join '/')]"
    }
    elseif ($Default) {
        $suffix = " [$Default]"
    }
    else {
        $suffix = ""
    }

    $line = Read-Host "$Prompt$suffix"
    if ([string]::IsNullOrWhiteSpace($line)) {
        return $Default
    }
    return $line.Trim()
}

function Resolve-Answer {
    param([object]$Question)

    $id = $Question.id
    $default = ""
    if ($Question.PSObject.Properties.Name -contains 'default') {
        $default = [string]$Question.default
    }
    if ($Question.PSObject.Properties.Name -contains 'default_from' -and $Question.default_from -eq "repo_dir_name") {
        $default = Split-Path -Leaf $script:RepoRoot
    }

    $options = @()
    if ($Question.PSObject.Properties.Name -contains 'options') {
        $options = @($Question.options)
    }

    $type = $Question.'type'
    $prompt = $Question.prompt

    if ($NonInteractive) {
        if ($script:Answers.ContainsKey($id)) { return $script:Answers[$id] }
        return $default
    }

    if ($script:Answers.ContainsKey($id)) {
        $confirmed = Ask-Question -Prompt "$prompt (press Enter to keep '$($script:Answers[$id])', or type new value)" -Default ([string]$script:Answers[$id])
        if (-not [string]::IsNullOrWhiteSpace($confirmed)) {
            $script:Answers[$id] = $confirmed
        }
        return $script:Answers[$id]
    }

    if ($type -eq "bool") {
        $val = Ask-Question -Prompt $prompt -Default $default -IsBool
        return ($val -match "^[yY]")
    }
    if ($type -eq "multiline") {
        Write-Host $prompt -ForegroundColor Cyan
        if ($Question.PSObject.Properties.Name -contains 'examples') {
            Write-Host "Examples:" -ForegroundColor DarkGray
            foreach ($ex in $Question.examples) { Write-Host "  $ex" -ForegroundColor DarkGray }
        }
        Write-Host "(Finish with a single '.' on its own line)" -ForegroundColor DarkGray
        $lines = New-Object System.Collections.Generic.List[string]
        while ($true) {
            $l = Read-Host ""
            if ($l -eq ".") { break }
            $lines.Add($l) | Out-Null
        }
        return ($lines -join "`n")
    }
    if ($options.Count -gt 0) {
        return Ask-Question -Prompt $prompt -Default $default -Options $options
    }
    return Ask-Question -Prompt $prompt -Default $default
}

function Run-Phase {
    param([object]$Phase)
    Write-Host ""
    Write-Host "=== $($Phase.title) ===" -ForegroundColor Yellow
    Write-Host $Phase.description -ForegroundColor DarkGray
    Write-Host ""
    $phaseAnswers = @{}
    foreach ($q in $Phase.questions) {
        $val = Resolve-Answer -Question $q
        $phaseAnswers[$q.id] = $val
        $script:Answers[$q.id] = $val
    }
    return $phaseAnswers
}

# --- file writers ----------------------------------------------------------

function Backup-File {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    if (-not $script:BackupRoot) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        if ($BackupDir) {
            $script:BackupRoot = $BackupDir
        } else {
            $script:BackupRoot = Join-Path $script:RepoRoot ".opencode\.backups\$stamp"
        }
    }
    $rel = $Path.Substring($script:RepoRoot.Length).TrimStart('\','/')
    $dest = Join-Path $script:BackupRoot $rel
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Copy-Item -LiteralPath $Path -Destination $dest -Force
    $script:Backups.Add($rel) | Out-Null
}

function Write-Generated {
    param(
        [string]$Path,
        [string]$Content,
        [switch]$Overwrite
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        if ($WhatIf -or $VerifyOnly) {
            $script:Skipped.Add("DIR  $parent (would create)") | Out-Null
        } else {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
    }
    if (Test-Path -LiteralPath $Path) {
        $current = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
        if ($current -eq $Content) {
            $script:Skipped.Add("FILE $Path (unchanged)") | Out-Null
            return
        }
        if (-not $Overwrite) {
            $script:Skipped.Add("FILE $Path (exists, kept)") | Out-Null
            return
        }
        if ($VerifyOnly) {
            $script:Skipped.Add("FILE $Path (would update)") | Out-Null
            return
        }
        Backup-File -Path $Path
        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        $script:Updated.Add("FILE $Path") | Out-Null
        return
    }
    if ($VerifyOnly) {
        $script:Skipped.Add("FILE $Path (would create)") | Out-Null
        return
    }
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    $script:Created.Add("FILE $Path") | Out-Null
}

# --- content builders ------------------------------------------------------

function Build-ProjectMd {
    param([hashtable]$A)
    $entities = ($A.domain_entities -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join ", "
    $sb = New-Object System.Text.StringBuilder

    [void]$sb.AppendLine("# $($A.project_display_name)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("> **Single source of truth for project info, conventions, and architecture.**")
    [void]$sb.AppendLine("> The opencode agent system reads from `docs/project.md` and `docs/context/` directly.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Overview")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- **Project Name**: $($A.project_name)")
    [void]$sb.AppendLine("- **Description**: $($A.project_description)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Technology Stack")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- **Primary language**: $($A.primary_language)")
    [void]$sb.AppendLine("- **Framework**: $($A.framework)")
    [void]$sb.AppendLine("- **Database**: $($A.database)")
    [void]$sb.AppendLine("- **ORM**: $($A.orm)")
    [void]$sb.AppendLine("- **Auth**: $($A.auth)")
    [void]$sb.AppendLine("- **Secrets**: $($A.secrets)")
    [void]$sb.AppendLine("- **Architecture pattern**: $($A.architecture_pattern)")

    if ($A.slices) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("## Slices")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("The orchestrator uses this table to route incoming tasks. Each slice is a 'pizza slice' - a major area of the codebase that the human has explicitly demarcated. Tasks that fall inside a slice should start by reading the listed entry points and using the listed primary agents.")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Slice | Description | Entry points | Primary agents |")
        [void]$sb.AppendLine("|---|---|---|---|")
        foreach ($line in ($A.slices -split "`n" | Where-Object { $_ -and $_.Trim() })) {
            $parts = $line -split '\|' | ForEach-Object { $_.Trim() }
            if ($parts.Count -lt 4) { continue }
            [void]$sb.AppendLine("| $($parts[0]) | $($parts[1]) | $($parts[2]) | $($parts[3]) |")
        }
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("If a task does not clearly belong to any slice, the orchestrator MUST add a new slice row to this table and explain the rationale before starting work.")
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Commands")
    [void]$sb.AppendLine("")
    $hasCmd = $false
    if ($A.dev_command)      { [void]$sb.AppendLine("- Dev: ``$($A.dev_command)``"); $hasCmd = $true }
    if ($A.db_command)       { [void]$sb.AppendLine("- Start DB: ``$($A.db_command)``"); $hasCmd = $true }
    if ($A.db_reset_command) { [void]$sb.AppendLine("- Reset DB: ``$($A.db_reset_command)``"); $hasCmd = $true }
    if ($A.docker_command)   { [void]$sb.AppendLine("- Docker: ``$($A.docker_command)``"); $hasCmd = $true }
    if (-not $hasCmd)        { [void]$sb.AppendLine("- (add commands)") }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Backend Structure")
    [void]$sb.AppendLine("")
    $backendLines = @($A.backend_structure -split "`n" | Where-Object { $_ -and $_.Trim() })
    if ($backendLines.Count -gt 0) {
        foreach ($b in $backendLines) { [void]$sb.AppendLine("  - ``$b``") }
    } else {
        [void]$sb.AppendLine("  - (add structure)")
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Key Conventions")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- All documentation and comments in **$($A.doc_language)**")
    [void]$sb.AppendLine("- See `docs/context/` for strategic docs")

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Domain Entities")
    [void]$sb.AppendLine("")
    if ([string]::IsNullOrWhiteSpace($entities)) {
        [void]$sb.AppendLine("- (add entities)")
    } else {
        [void]$sb.AppendLine("- $entities")
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Context Index")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("See `docs/context/README.md` for the full index of strategic docs.")

    return $sb.ToString()
}

function Build-ContextDoc {
    param([string]$Id, $Template)
    $body = $Template.default_body
    $title = $Template.title
    return @"
# $title

> Generated by `install-agent.ps1`. Fill in the substance.

$body
"@
}

function Build-ContextReadme {
    param([string[]]$SelectedIds, $Templates)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Context Folder - Project Knowledge Base")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Single source of truth for project strategies, architecture, and conventions.**")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Each file covers ONE aspect of the project. Agents read on demand, reference rather than duplicate.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## File Index")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| File | Purpose | When to Use |")
    [void]$sb.AppendLine("|---|---|---|")
    foreach ($id in $SelectedIds) {
        if (-not $Templates.ContainsKey($id)) { continue }
        $t = $Templates[$id]
        $fn = $t.filename
        $tt = $t.title
        [void]$sb.AppendLine("| ``$fn`` | $tt | When working on $($tt.ToLower()) |")
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Maintenance")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- One topic per file")
    [void]$sb.AppendLine("- Cross-reference related files")
    [void]$sb.AppendLine("- Update this README when adding a new file")
    return $sb.ToString()
}

function Build-SlangTemplate {
    param([string]$SlangBlock)
    $rows = ""
    if ($SlangBlock) {
        foreach ($line in ($SlangBlock -split "`n" | Where-Object { $_ -and $_.Trim() })) {
            $parts = $line -split '\|' | ForEach-Object { $_.Trim() }
            if ($parts.Count -lt 4) { continue }
            $rows += "| $($parts[0]) | $($parts[1]) | $($parts[2]) | $($parts[3]) |`n"
        }
    }
    if (-not $rows) { $rows = "| | | | |`n" }
    return @"
# Project Slang Snapshot

> **ROLE**: per-session project slang dictionary (lunfardo del proyecto).
> NOT a copy of `docs/project.md`. The source-of-truth project info lives in `docs/project.md` and `docs/context/`.
> This snapshot is a dictionary in the same spirit as `humano.md`, but for the project domain: internal jargon, abbreviations, how this codebase names things.

## How This File Differs From `humano.md`

| File | Scope | Subject |
|---|---|---|
| `humano.md` | How the human talks | Colloquialisms, slang, personal vocabulary in their language |
| `project.md` (this) | How the project names things | Internal jargon, abbreviations, model names, business terms |

Both files are **dictionaries for translation**, not style-matching guides.

## Project Slang

| Term | Meaning | Location (code) | Confidence |
|---|---|---|---|
$rows
## How to Populate

1. Infer from the codebase
2. Listen to the human
3. Confidence levels: High (in code + used by human), Medium, Low
4. Update incrementally as new terms appear
"@
}

function Get-AgentBody {
    param([string]$Id)
    $coderAngularBody = "# Coder Angular Subagent`n`nAngular implementation. Implement features, fix bugs, refactor the Angular frontend.`n`n**Project context**: read `docs/project.md` (entry point, Slices table) and the Angular docs in `docs/context/` (source of truth).`n`n## Rules`n`n- Follow the matched slice's primary doc in `docs/context/` for the Angular stack`n- All comments and docs in ENGLISH`n- Run the canonical test/lint/build commands from `docs/project.md` before reporting done`n- Never commit without explicit instruction"
    $coderGoBody = "# Coder Go Subagent`n`nGo implementation. Implement features, fix bugs, refactor the Go backend.`n`n**Project context**: read `docs/project.md` (entry point, Slices table) and the Go docs in `docs/context/` (source of truth).`n`n## Rules`n`n- Follow the matched slice's primary doc in `docs/context/` for the Go stack`n- All comments and docs in ENGLISH`n- Run the canonical test/lint/build commands from `docs/project.md` before reporting done`n- Never commit without explicit instruction"
    $testerBody = "# Tester Subagent`n`nWrite and run tests.`n`n**Project context**: read `docs/project.md` (entry point). For test conventions see `docs/context/conventions/project-rules.md`.`n`n## Rules`n`n- Tests next to source files`n- Mock external deps`n- All test names and comments in ENGLISH"
    $reviewerBody = "# Reviewer Subagent`n`nAnalyze code - never modify it.`n`n**Project context**: read `docs/project.md` (entry point) and the relevant files in `docs/context/`.`n`n## Checklist`n`n1. Architecture compliance (see `docs/context/architecture.md`)`n2. Development standards (see `docs/context/project-rules.md`)`n3. Security`n4. Performance`n5. Anti-patterns`n6. Testing`n`n## Output`n`nReturn structured `ReviewerOutput` JSON (see `.opencode/agents/subagents/reviewer.md`)."
    $architectBody = "# Architect Subagent`n`nDesign system architecture, define module boundaries, establish patterns.`n`n**Project context**: read `docs/project.md` (entry point) and `docs/context/architecture.md`.`n`n## Principles`n`n- Favor simplicity`n- Design for testability and maintainability`n- Document decisions with rationale`n- All documentation in ENGLISH"
    $explorerBody = "# Explorer Subagent`n`nRead and analyze the codebase - never modify code.`n`n**Project context**: read `docs/project.md` (entry point) for module layout, then drill into the relevant source paths.`n`n## Approach`n`n- Use grep/glob/read effectively`n- Report file paths and line numbers`n- For architectural questions, consult `docs/context/architecture.md`"
    $documenterBody = "# Documenter Subagent`n`nWrite and maintain documentation.`n`n**Project context**: read `docs/project.md` and the relevant files in `docs/context/`.`n`n## Rules`n`n- One topic per file`n- Reference, do not duplicate`n- All documentation in ENGLISH"
    $projectContextBody = "# Project Context Subagent`n`nReads and writes `docs/` on demand.`n`n## Read Workflow`n`n1. Read `docs/project.md` for orientation`n2. Read `docs/context/README.md` to find the relevant context file`n3. If unclear, use grep/glob to search `docs/` and the codebase`n4. Return: relevant excerpt + file path + line numbers`n`n## Write Workflow`n`n1. Identify the target doc (existing in `docs/project.md`, `docs/context/`, or new)`n2. Read the doc to understand its structure`n3. Edit or create the doc, keeping the tone consistent`n4. If a new context file is created, add an entry to `docs/context/README.md`"
    $defaultBody = "# $Id Subagent`n`nGenerated by install-agent.ps1. Fill in the agent's responsibilities here.`n`n**Project context**: read `docs/project.md` (entry point)."
    if ($Id -eq "coder-angular") { return $coderAngularBody }
    if ($Id -eq "coder-go") { return $coderGoBody }
    if ($Id -eq "tester") { return $testerBody }
    if ($Id -eq "reviewer") { return $reviewerBody }
    if ($Id -eq "architect") { return $architectBody }
    if ($Id -eq "explorer") { return $explorerBody }
    if ($Id -eq "documenter") { return $documenterBody }
    if ($Id -eq "project-context") { return $projectContextBody }
    return $defaultBody
}

function Get-AgentTemp {
    param([string]$Id)
    if ($Id -eq "delivery") { return 0.3 }
    if ($Id -eq "tester") { return 0.2 }
    if ($Id -eq "explorer") { return 0.1 }
    if ($Id -eq "vision-relay") { return 0.1 }
    if ($Id -eq "external-scout") { return 0.1 }
    if ($Id -eq "interpreter") { return 0.1 }
    if ($Id -eq "project-context") { return 0.2 }
    if ($Id -eq "documenter") { return 0.2 }
    return $null
}

function Build-AgentFile {
    param([string]$Id, $Ctx)
    $body = Get-AgentBody -Id $Id
    $model = Get-AgentModel -Id $Id
    $temp = Get-AgentTemp -Id $Id
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("description: $Id subagent")
    [void]$sb.AppendLine("mode: subagent")
    [void]$sb.AppendLine("model: $model")
    if ($temp) { [void]$sb.AppendLine("temperature: $temp") }
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
    [void]$sb.Append($body)
    return $sb.ToString()
}

function Build-OpencodeJson {
    param([string]$DefaultAgent, $Subagents, [string]$RepoPath)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('{')
    [void]$sb.AppendLine('  "$schema": "https://opencode.ai/config.json",')
    [void]$sb.AppendLine("  ""default_agent"": ""$DefaultAgent"",")
    [void]$sb.AppendLine('  "compaction": {'),
    [void]$sb.AppendLine('    "auto": true,')
    [void]$sb.AppendLine('    "prune": true,')
    [void]$sb.AppendLine('    "reserved": 10000')
    [void]$sb.AppendLine('  },')
    [void]$sb.AppendLine('  "permission": { "question": "ask" },')
    [void]$sb.AppendLine('  "instructions": [')
    [void]$sb.AppendLine('    "docs/project.md",')
    [void]$sb.AppendLine('    ".opencode/protocols/prompt-pipeline.md"')
    [void]$sb.AppendLine('  ]')
    [void]$sb.AppendLine('}')
    return $sb.ToString()
}

# --- main flow --------------------------------------------------------------

$script:Schema = Read-Schema

if ($AnswersFile -and (Test-Path -LiteralPath $AnswersFile)) {
    $json = Get-Content -LiteralPath $AnswersFile -Raw | ConvertFrom-Json
    foreach ($p in $json.PSObject.Properties) {
        $script:Answers[$p.Name] = [string]$p.Value
    }
}

Write-Host "Agent Installer - Repo: $script:RepoRoot" -ForegroundColor Green
if ($WhatIf)     { Write-Host "MODE: WhatIf (no writes)" -ForegroundColor Magenta }
if ($VerifyOnly) { Write-Host "MODE: VerifyOnly (no writes)" -ForegroundColor Magenta }
if ($Update)     { Write-Host "MODE: Update (preserve existing, prompt for changes)" -ForegroundColor Magenta }

$phase1 = Run-Phase -Phase ($script:Schema.phases[0])
$phase2 = Run-Phase -Phase ($script:Schema.phases[1])
$phase3 = Run-Phase -Phase ($script:Schema.phases[2])
$phase4 = Run-Phase -Phase ($script:Schema.phases[3])

Write-Host ""
Write-Host "=== Generating files ===" -ForegroundColor Yellow

# project.md
$projectPath = Join-Path $script:RepoRoot "docs\project.md"
Write-Generated -Path $projectPath -Content (Build-ProjectMd -A $phase1) -Overwrite:$Update

# context docs
$contextDir = Join-Path $script:RepoRoot "docs\context"
$selected = @($phase2.context_selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) | Select-Object -Unique
$tplHashtable = @{}
foreach ($p in $script:Schema.phases[1].context_templates.PSObject.Properties) {
    $tplHashtable[$p.Name] = $p.Value
}
foreach ($id in $selected) {
    if (-not $tplHashtable.ContainsKey($id)) { continue }
    $tpl = $tplHashtable[$id]
    $path = Join-Path $contextDir $tpl.filename
    Write-Generated -Path $path -Content (Build-ContextDoc -Id $id -Template $tpl) -Overwrite:$Update
}
$readmePath = Join-Path $contextDir "README.md"
Write-Generated -Path $readmePath -Content (Build-ContextReadme -SelectedIds $selected -Templates $tplHashtable) -Overwrite:$Update

# (No more session-templates/ — the project slang snapshot is part of docs/, not a separate template.)

# agents
$agentsDir = Join-Path $script:RepoRoot ".opencode\agents\subagents"
$subagentIds = @($phase4.selected_subagents -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) | Select-Object -Unique
foreach ($id in $subagentIds) {
    $path = Join-Path $agentsDir "$id.md"
    Write-Generated -Path $path -Content (Build-AgentFile -Id $id -Ctx @{}) -Overwrite:$Update
}

# opencode.json
$opencodePath = Join-Path $script:RepoRoot "opencode.json"
Write-Generated -Path $opencodePath -Content (Build-OpencodeJson -DefaultAgent $phase4.default_agent -Subagents $subagentIds -RepoPath $script:RepoRoot) -Overwrite:$Update

# report
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Yellow
Write-Host "Created: $($script:Created.Count)"
$script:Created | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
Write-Host "Updated: $($script:Updated.Count)"
$script:Updated  | ForEach-Object { Write-Host "  ~ $_" -ForegroundColor Cyan }
Write-Host "Skipped: $($script:Skipped.Count)"
$script:Skipped  | ForEach-Object { Write-Host "  = $_" -ForegroundColor DarkGray }
if ($script:Backups.Count -gt 0) {
    Write-Host ""
    Write-Host "Backups at: $script:BackupRoot" -ForegroundColor Magenta
    $script:Backups | ForEach-Object { Write-Host "  ! $_" -ForegroundColor Magenta }
}
