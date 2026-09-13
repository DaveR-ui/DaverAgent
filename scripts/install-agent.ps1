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

    # The nine sections are fixed (onrails 06 §Section anatomy). The Slices
    # section is ALWAYS emitted: an empty Slices table is legal at birth, so the
    # heading + 5-column header must never be dropped.
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Slices")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("The orchestrator uses this table to route incoming tasks. Each slice is a 'pizza slice' - a major area of the codebase that the human has explicitly demarcated. Tasks that fall inside a slice should start by reading the listed entry points and using the listed primary agents.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Slice | Description | Keywords | Entry points | Primary agents |")
    [void]$sb.AppendLine("|---|---|---|---|---|")
    if ($A.slices) {
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
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("If a task does not clearly belong to any slice, the orchestrator MUST add a new slice row to this table and explain the rationale before starting work.")

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Commands")
    [void]$sb.AppendLine("")
    $hasCmd = $false
    if ($A.dev_command)      { [void]$sb.AppendLine("- Dev: ``$($A.dev_command)``"); $hasCmd = $true }
    if ($A.serve_command)    { [void]$sb.AppendLine("- Serve: ``$($A.serve_command)``"); $hasCmd = $true }
    if ($A.build_command)    { [void]$sb.AppendLine("- Build: ``$($A.build_command)``"); $hasCmd = $true }
    if ($A.test_command)     { [void]$sb.AppendLine("- Test: ``$($A.test_command)``"); $hasCmd = $true }
    if ($A.lint_command)     { [void]$sb.AppendLine("- Lint: ``$($A.lint_command)``"); $hasCmd = $true }
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
    [void]$sb.AppendLine("Project slang: [snapshot](./context/project-slang.md).")

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
    # The slang snapshot lives under context/ as a context doc, so it is
    # registered from this hub like every other selected context doc.
    [void]$sb.AppendLine("| ``project-slang.md`` | Project Slang Snapshot | When working on project slang and internal jargon |")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Maintenance")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- One topic per file")
    [void]$sb.AppendLine("- Cross-reference related files")
    [void]$sb.AppendLine("- Update this hub when adding a new file")
    return $sb.ToString()
}

# --- bootstrap corpus model ------------------------------------------------

# Describes the docs a fresh bootstrap creates, using the consumer validator's
# path-based classification (entry | generated | hub | context | note). Both
# Build-Index and Build-TagIndex derive their generated regions from this single
# model, so the two surfaces cannot drift. `rel` paths are docs-root relative
# (no leading `docs/`), matching the validator's render regions byte for byte.
function Get-BootstrapDocs {
    param([string[]]$SelectedIds, $Templates, [hashtable]$A)

    $pdesc = $A.project_description
    if ([string]::IsNullOrWhiteSpace($pdesc)) {
        $pdesc = "$($A.project_name) project facts: stack, commands, slices, domain entities"
    }

    $docs = New-Object System.Collections.Generic.List[object]

    # Root entry point. `cls = entry`; the validator's classCounts folds entry
    # into the context-docs count and treeLabel renders it "context-doc (entry)".
    $docs.Add(@{
        rel = "project.md"; name = "project.md"; dir = ""; cls = "entry"; id = $null;
        tags = [string[]]@("project"); description = $pdesc;
        h1 = [string]$A.project_display_name
    })

    # context/ hub. It carries the note contract (id/category/...), which has no
    # `description` key - so its tag-index label falls back to the H1, exactly
    # as the validator's renderTagsRegion does. Being a note-class doc it also
    # renders its `id` in the index tree.
    $docs.Add(@{
        rel = "context/context-index.md"; name = "context-index.md"; dir = "context"; cls = "hub"; id = "context-index";
        tags = [string[]]@("context", "index"); description = $null;
        h1 = "Context Folder - Project Knowledge Base"
    })

    # Project slang snapshot: lives under context/ as a context doc.
    $docs.Add(@{
        rel = "context/project-slang.md"; name = "project-slang.md"; dir = "context"; cls = "context"; id = $null;
        tags = [string[]]@("slang", "glossary");
        description = "Per-session project slang dictionary (internal jargon, abbreviations)";
        h1 = "Project Slang Snapshot"
    })

    # Selected context docs.
    foreach ($id in $SelectedIds) {
        if (-not $Templates.ContainsKey($id)) { continue }
        $t = $Templates[$id]
        $desc = $t.description
        if ([string]::IsNullOrWhiteSpace($desc)) { $desc = $t.title }
        $tagList = @()
        if ($t.tags) { $tagList = [string[]]@($t.tags) }
        $docs.Add(@{
            rel = "context/$($t.filename)"; name = $t.filename; dir = "context"; cls = "context"; id = $null;
            tags = $tagList; description = $desc; h1 = [string]$t.title
        })
    }

    # Generated artifacts: listed in the tree / counted, but never tagged.
    $docs.Add(@{ rel = "tag-index.md"; name = "tag-index.md"; dir = ""; cls = "generated"; id = $null; tags = [string[]]@(); description = $null; h1 = $null })
    $docs.Add(@{ rel = "index.md"; name = "index.md"; dir = ""; cls = "generated"; id = $null; tags = [string[]]@(); description = $null; h1 = $null })

    return $docs
}

# One tree line in the index region. The separator is an em dash (U+2014) and
# the class label matches the validator's treeLabel/idSuffix exactly (note-class
# docs carrying an `id` append `, id: \`<id>\``).
function Format-IndexTreeLine {
    param([hashtable]$Doc, [string]$Indent)
    $labels = @{ entry = "context-doc (entry)"; context = "context-doc"; hub = "hub"; generated = "generated" }
    $label = $labels[$Doc.cls]
    if (-not $label) { $label = "note" }
    $idSuffix = ""
    if (($Doc.cls -eq "note" -or $Doc.cls -eq "hub") -and $Doc.id) {
        $idSuffix = ", id: ``$($Doc.id)``"
    }
    return "$Indent- $($Doc.name) $([char]0x2014) $label$idSuffix"
}

function Build-TagIndex {
    param([string[]]$SelectedIds, $Templates, [hashtable]$A)
    $today = (Get-Date -Format "yyyy-MM-dd")
    $docs = @(Get-BootstrapDocs -SelectedIds $SelectedIds -Templates $Templates -A $A)

    # The validator walks the corpus sorted by POSIX relative path (ordinal), and
    # uses default (code-unit) sort for tag keys. `Sort-Object` is culture-aware,
    # so every sort here goes through [System.StringComparer]::Ordinal.
    $rels = [string[]]@($docs | ForEach-Object { $_.rel })
    [Array]::Sort($rels, [System.StringComparer]::Ordinal)
    $byRel = @{}
    foreach ($d in $docs) { $byRel[$d.rel] = $d }

    # Real tag -> docs inversion for the docs this bootstrap creates. Docs added
    # later by humans are folded in when the Node validator regenerates the region
    # (`node docs/validate.js --write`).
    $byTag = @{}
    foreach ($rel in $rels) {
        $d = $byRel[$rel]
        if ($d.cls -eq "generated") { continue }
        if (-not $d.tags) { continue }
        $label = $d.description
        if ([string]::IsNullOrWhiteSpace($label)) { $label = $d.h1 }
        if ([string]::IsNullOrWhiteSpace($label)) { $label = $d.rel }
        $entry = "- ``$($d.rel)`` - $label"
        foreach ($tag in $d.tags) {
            if (-not $byTag.ContainsKey($tag)) {
                $byTag[$tag] = New-Object System.Collections.Generic.List[string]
            }
            $byTag[$tag].Add($entry)
        }
    }
    $tagNames = [string[]]@($byTag.Keys)
    [Array]::Sort($tagNames, [System.StringComparer]::Ordinal)

    # Region body mirrors the validator's renderTagsRegion byte for byte: the
    # body opens with a blank line, then each distinct tag is rendered as a blank
    # line + "## <tag>" + a blank line + one ref line per doc, and the body
    # closes with a blank line immediately before the END marker.
    $body = New-Object System.Collections.Generic.List[string]
    foreach ($tag in $tagNames) {
        $body.Add("")
        $body.Add("## $tag")
        $body.Add("")
        foreach ($entry in $byTag[$tag]) { $body.Add($entry) }
    }
    $body.Add("")

    # LF line endings so the generated region matches the validator's output.
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Tag Index")
    $lines.Add("")
    $lines.Add("> GENERATED surface. Do not hand-edit inside the markers.")
    $lines.Add("> Regenerate with ``node docs/validate.js --write``.")
    $lines.Add("")
    $lines.Add("<!-- BEGIN GENERATED: tags -->")
    $lines.Add("<!-- snapshot: $today -->")
    foreach ($b in $body) { $lines.Add($b) }
    $lines.Add("<!-- END GENERATED: tags -->")
    return (($lines -join "`n") + "`n")
}

function Build-Index {
    param([string[]]$SelectedIds, $Templates, [hashtable]$A)
    $today = (Get-Date -Format "yyyy-MM-dd")
    $docs = @(Get-BootstrapDocs -SelectedIds $SelectedIds -Templates $Templates -A $A)
    $byRel = @{}
    foreach ($d in $docs) { $byRel[$d.rel] = $d }

    $ctx = 0; $note = 0; $hub = 0
    foreach ($d in $docs) {
        # The validator's classCounts folds entry + context into the context bucket.
        if ($d.cls -eq "entry" -or $d.cls -eq "context") { $ctx++ }
        elseif ($d.cls -eq "hub") { $hub++ }
        elseif ($d.cls -eq "note") { $note++ }
    }

    # Region body mirrors the validator's renderIndexRegion. All bootstrap names
    # are lowercase, so ordinal sort matches its case-insensitive compare.
    $body = New-Object System.Collections.Generic.List[string]
    $body.Add("## Generated index")
    $body.Add("")
    $body.Add("### Overview")
    $body.Add("")
    $body.Add("- Markdown files: $($docs.Count)")
    $body.Add("- Context docs: $ctx | Notes: $note | Hubs: $hub")
    $body.Add("")
    $body.Add("### Tree")
    $body.Add("")

    # Root files first: project.md, then tag-index.md, then any other root file.
    # index.md never lists itself (mirrors the validator's renderIndexRegion).
    foreach ($rel in @("project.md", "tag-index.md")) {
        if ($byRel.ContainsKey($rel)) {
            $body.Add((Format-IndexTreeLine -Doc $byRel[$rel] -Indent ""))
        }
    }
    $rootRest = @($docs | Where-Object { $_.dir -eq "" -and $_.rel -ne "index.md" -and $_.rel -ne "project.md" -and $_.rel -ne "tag-index.md" })
    $rootRels = [string[]]@($rootRest | ForEach-Object { $_.rel })
    [Array]::Sort($rootRels, [System.StringComparer]::Ordinal)
    foreach ($rel in $rootRels) { $body.Add((Format-IndexTreeLine -Doc $byRel[$rel] -Indent "")) }

    # Folders (ordinal), files inside each folder (ordinal).
    $dirs = [string[]]@($docs | Where-Object { $_.dir -ne "" } | ForEach-Object { $_.dir } | Select-Object -Unique)
    [Array]::Sort($dirs, [System.StringComparer]::Ordinal)
    foreach ($dir in $dirs) {
        $body.Add("- $dir/")
        $fileRels = [string[]]@($docs | Where-Object { $_.dir -eq $dir } | ForEach-Object { $_.rel })
        [Array]::Sort($fileRels, [System.StringComparer]::Ordinal)
        foreach ($rel in $fileRels) {
            $body.Add((Format-IndexTreeLine -Doc $byRel[$rel] -Indent "  "))
        }
    }

    # LF line endings so the generated region matches the validator's output.
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Corpus Index")
    $lines.Add("")
    $lines.Add("> GENERATED surface. Do not hand-edit inside the markers.")
    $lines.Add("> Regenerate with ``node docs/validate.js --write``.")
    $lines.Add("")
    $lines.Add("<!-- BEGIN GENERATED: index -->")
    $lines.Add("<!-- snapshot: $today -->")
    foreach ($b in $body) { $lines.Add($b) }
    $lines.Add("<!-- END GENERATED: index -->")
    return (($lines -join "`n") + "`n")
}

function Build-SlangTemplate {
    param([string]$SlangBlock)
    $today = (Get-Date -Format "yyyy-MM-dd")
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
last_updated: $today
status: draft
description: Per-session project slang dictionary (internal jargon, abbreviations)
tags: [slang, glossary]
version: 1.0
---
# Project Slang Snapshot

> **ROLE**: per-session project slang dictionary (lunfardo del proyecto).
> NOT a copy of `docs/project.md`. The source-of-truth project info lives in `docs/project.md` and `docs/context/`.
> This snapshot is a dictionary for the project domain: internal jargon, abbreviations, how this codebase names things.

## How This File Differs From `docs/project.md`

| File | Scope | Subject |
|---|---|---|
| `docs/project.md` | Canonical project facts | Stack, commands, slices, domain entities |
| `docs/context/project-slang.md` (this) | How the project names things | Internal jargon, abbreviations, model names, business terms |

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

# generated tag index (onrails lowercase tag-index.md, marker regions).
# Write-if-missing ONLY: the installer creates the artifact once with its marker
# skeleton on first bootstrap; regeneration of the marker region is owned by the
# AUTOMATIC, no-confirmation `node docs/validate.js --write` call below. That
# regeneration is marker-region-scoped, so human content outside the markers is
# preserved and the file is never whole-file clobbered on later runs.
$tagIndexPath = Join-Path $script:RepoRoot "docs\tag-index.md"
Write-Generated -Path $tagIndexPath -Content (Build-TagIndex -SelectedIds $selected -Templates $tplHashtable -A $phase1) -Overwrite:$false

# generated corpus index (onrails index.md, marker region; mirrors the validator).
# Same write-if-missing policy as tag-index.md above: created once on first
# bootstrap, then regenerated marker-scoped by `node docs/validate.js --write`.
$indexPath = Join-Path $script:RepoRoot "docs\index.md"
Write-Generated -Path $indexPath -Content (Build-Index -SelectedIds $selected -Templates $tplHashtable -A $phase1) -Overwrite:$false

# project slang snapshot (context doc under docs/context/)
$slangPath = Join-Path $script:RepoRoot "docs\context\project-slang.md"
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
