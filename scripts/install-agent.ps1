[CmdletBinding()]
param(
    # Target project root (where docs/ will be generated). Defaults to the
    # current directory. This is the per-project DOCS bootstrap; the global agent
    # system is installed separately via scripts/bootstrap.sh.
    [string]$RepoPath,
    [switch]$NonInteractive,
    [string]$AnswersFile,
    [switch]$WhatIf,
    [switch]$VerifyOnly,
    [switch]$Update,
    [string]$BackupDir
)

$ErrorActionPreference = "Stop"
if (-not $RepoPath) { $RepoPath = (Get-Location).Path }
$script:RepoRoot = (Resolve-Path -LiteralPath $RepoPath).Path
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
            $script:BackupRoot = Join-Path $script:RepoRoot ".agent-backups\$stamp"
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
    $today = (Get-Date -Format "yyyy-MM-dd")
    $entities = ($A.domain_entities -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join ", "
    $desc = $A.project_description
    if ([string]::IsNullOrWhiteSpace($desc)) { $desc = "$($A.project_name) project facts: stack, commands, slices, domain entities" }
    $lang = $A.doc_language
    if ([string]::IsNullOrWhiteSpace($lang)) { $lang = "en" }
    $sb = New-Object System.Text.StringBuilder

    # context-doc frontmatter + entry-point-only doc_language (onrails 02 §4)
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("last_updated: $today")
    [void]$sb.AppendLine("status: draft")
    [void]$sb.AppendLine("description: $desc")
    [void]$sb.AppendLine("tags: [project]")
    [void]$sb.AppendLine("version: 1.0")
    [void]$sb.AppendLine("doc_language: $lang")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
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
        [void]$sb.AppendLine("| Slice | Description | Keywords | Entry points | Primary agents |")
        [void]$sb.AppendLine("|---|---|---|---|---|")
        foreach ($line in ($A.slices -split "`n" | Where-Object { $_ -and $_.Trim() })) {
            $parts = $line -split '\|' | ForEach-Object { $_.Trim() }
            # Canonical row: slice | description | keywords | entry points | primary agents.
            # A legacy 4-field row (no keywords) is still accepted.
            if ($parts.Count -ge 5) {
                [void]$sb.AppendLine("| $($parts[0]) | $($parts[1]) | $($parts[2]) | $($parts[3]) | $($parts[4]) |")
            }
            elseif ($parts.Count -ge 4) {
                [void]$sb.AppendLine("| $($parts[0]) | $($parts[1]) |  | $($parts[2]) | $($parts[3]) |")
            }
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
    [void]$sb.AppendLine("## Repository Structure")
    [void]$sb.AppendLine("")
    # Canonical question id is `repository_structure`; accept the legacy
    # `backend_structure` key from an older -AnswersFile (it is loaded into
    # $script:Answers, not into the current phase hashtable).
    $structureRaw = $A.repository_structure
    if (-not $structureRaw) { $structureRaw = $script:Answers['backend_structure'] }
    $structureLines = @($structureRaw -split "`n" | Where-Object { $_ -and $_.Trim() })
    if ($structureLines.Count -gt 0) {
        foreach ($b in $structureLines) { [void]$sb.AppendLine("  - ``$b``") }
    } else {
        [void]$sb.AppendLine("  - (add structure)")
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Key Conventions")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- All documentation and comments in **$lang**")
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
    [void]$sb.AppendLine("See [the context index](./context/context-index.md) for the full index of strategic docs.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Project procedures live in `docs/protocols/` (hub-less); register each one with a link here.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Project slang: [snapshot](./project-slang.md).")

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Common Lookups")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Map recurring symptoms/questions to the doc that answers them.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Lookup | Where |")
    [void]$sb.AppendLine("|---|---|")
    [void]$sb.AppendLine("| (add symptom) | ``docs/context/<doc>.md#anchor`` |")

    return $sb.ToString()
}

function Build-ContextDoc {
    param([string]$Id, $Template)
    $today = (Get-Date -Format "yyyy-MM-dd")
    $body = $Template.default_body
    $title = $Template.title
    $desc = $Template.description
    if ([string]::IsNullOrWhiteSpace($desc)) { $desc = $title }
    $tagList = "["
    if ($Template.tags) { $tagList += ($Template.tags -join ", ") }
    $tagList += "]"
    return @"
---
last_updated: $today
status: draft
description: $desc
tags: $tagList
version: 1.0
---
# $title

> Generated by `install-agent.ps1`. Fill in the substance.

$body
"@
}

function Build-ContextReadme {
    param([string[]]$SelectedIds, $Templates)
    $sb = New-Object System.Text.StringBuilder
    # context-index.md is a hub (`*-index.md`), so it carries the NOTE contract
    # (onrails 01 §hub rule).
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("id: context-index")
    [void]$sb.AppendLine("category: context")
    [void]$sb.AppendLine("tags: [context, index]")
    [void]$sb.AppendLine("aliases: []")
    [void]$sb.AppendLine("related: []")
    [void]$sb.AppendLine("version: 1.0")
    [void]$sb.AppendLine("status: draft")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
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
    [void]$sb.AppendLine("- Update this hub when adding a new file")
    return $sb.ToString()
}

function Build-TagIndex {
    param([string[]]$SelectedIds, $Templates)
    $today = (Get-Date -Format "yyyy-MM-dd")
    # Real tag -> doc inversion for the docs this bootstrap creates. Docs added
    # later by humans are folded in when the Node validator regenerates the region
    # (`node docs/validate.js --write`).
    $byTag = @{}
    $byTag['project'] = New-Object System.Collections.Generic.List[string]
    $byTag['project'].Add("- ``docs/project.md`` - Project facts")
    foreach ($id in $SelectedIds) {
        if (-not $Templates.ContainsKey($id)) { continue }
        $t = $Templates[$id]
        $desc = $t.description
        if ([string]::IsNullOrWhiteSpace($desc)) { $desc = $t.title }
        $entry = "- ``docs/context/$($t.filename)`` - $desc"
        if ($t.tags) {
            foreach ($tag in $t.tags) {
                if (-not $byTag.ContainsKey($tag)) { $byTag[$tag] = New-Object System.Collections.Generic.List[string] }
                $byTag[$tag].Add($entry)
            }
        }
    }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Tag Index")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("> GENERATED surface. Do not hand-edit inside the markers.")
    [void]$sb.AppendLine("> Regenerate with ``node docs/validate.js --write``.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("<!-- BEGIN GENERATED: tags -->")
    [void]$sb.AppendLine("<!-- snapshot: $today -->")
    foreach ($tag in ($byTag.Keys | Sort-Object)) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("## $tag")
        [void]$sb.AppendLine("")
        foreach ($entry in $byTag[$tag]) { [void]$sb.AppendLine($entry) }
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("<!-- END GENERATED: tags -->")
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
---
id: project-slang
category: project
tags: [slang, glossary]
aliases: []
related: []
version: 1.0
status: draft
---
# Project Slang Snapshot

> **ROLE**: per-session project slang dictionary (lunfardo del proyecto).
> NOT a copy of `docs/project.md`. The source-of-truth project info lives in `docs/project.md` and `docs/context/`.
> This snapshot is a dictionary for the project domain: internal jargon, abbreviations, how this codebase names things.

## How This File Differs From `docs/project.md`

| File | Scope | Subject |
|---|---|---|
| `docs/project.md` | Canonical project facts | Stack, commands, slices, domain entities |
| `docs/project-slang.md` (this) | How the project names things | Internal jargon, abbreviations, model names, business terms |

This file is a **dictionary for translation**, not a replacement for `docs/project.md`.

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


# --- main flow --------------------------------------------------------------

$script:Schema = Read-Schema

if ($AnswersFile -and (Test-Path -LiteralPath $AnswersFile)) {
    $json = Get-Content -LiteralPath $AnswersFile -Raw | ConvertFrom-Json
    foreach ($p in $json.PSObject.Properties) {
        $script:Answers[$p.Name] = [string]$p.Value
    }
}

Write-Host "Project Docs Bootstrap - Repo: $script:RepoRoot" -ForegroundColor Green
if ($WhatIf)     { Write-Host "MODE: WhatIf (no writes)" -ForegroundColor Magenta }
if ($VerifyOnly) { Write-Host "MODE: VerifyOnly (no writes)" -ForegroundColor Magenta }
if ($Update)     { Write-Host "MODE: Update (preserve existing, prompt for changes)" -ForegroundColor Magenta }

$phase1 = Run-Phase -Phase ($script:Schema.phases[0])
$phase2 = Run-Phase -Phase ($script:Schema.phases[1])
$phase3 = Run-Phase -Phase ($script:Schema.phases[2])
# Phase 4 (agent selection + opencode.json generation) is obsolete under the
# global model: agents and the runtime config are installed once per machine via
# scripts/bootstrap.sh. This script bootstraps per-project docs only.

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
$readmePath = Join-Path $contextDir "context-index.md"
Write-Generated -Path $readmePath -Content (Build-ContextReadme -SelectedIds $selected -Templates $tplHashtable) -Overwrite:$Update

# generated tag index (onrails lowercase tag-index.md, marker regions)
$tagIndexPath = Join-Path $script:RepoRoot "docs\tag-index.md"
Write-Generated -Path $tagIndexPath -Content (Build-TagIndex -SelectedIds $selected -Templates $tplHashtable) -Overwrite:$Update

# project slang snapshot
$slangPath = Join-Path $script:RepoRoot "docs\project-slang.md"
Write-Generated -Path $slangPath -Content (Build-SlangTemplate -SlangBlock $phase3.slang_block) -Overwrite:$Update

# derived documentation validator (per project; NOT wired into the global repo).
# Ships at docs/validate.js so its default corpus root is the project's docs/.
$validatorSrc = Join-Path $PSScriptRoot "..\templates\docs-validate.js"
$validatorDst = Join-Path $script:RepoRoot "docs\validate.js"
if (Test-Path -LiteralPath $validatorSrc) {
    if ($VerifyOnly -or $WhatIf) {
        $script:Skipped.Add("FILE $validatorDst (would install validator)") | Out-Null
    } else {
        Copy-Item -LiteralPath $validatorSrc -Destination $validatorDst -Force
        $script:Created.Add("FILE $validatorDst") | Out-Null
    }
}

# best-effort structure validation (Node required by the validator; skip if absent)
if (-not $VerifyOnly -and -not $WhatIf -and (Test-Path -LiteralPath $validatorDst)) {
    $node = Get-Command node -ErrorAction SilentlyContinue
    Write-Host ""
    if ($node) {
        Write-Host "=== Validating docs (node docs/validate.js) ===" -ForegroundColor Yellow
        # --write first so the generated tag index matches the validator's canonical render.
        & node $validatorDst --root (Join-Path $script:RepoRoot "docs") --write | Out-Null
        & node $validatorDst --root (Join-Path $script:RepoRoot "docs")
    } else {
        Write-Host "node not found; run 'node docs/validate.js' later to validate the generated docs." -ForegroundColor DarkGray
    }
}

# Global agent definitions and opencode.json are NOT generated here:
# they live in the global config (~/.config/opencode) installed by bootstrap.sh.

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
