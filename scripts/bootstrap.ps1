[CmdletBinding()]
param(
    [switch]$VerifyOnly,
    [string]$Target,
    [string]$RepoUrl,
    [string]$Branch
)

# bootstrap.ps1 - install or update the DaverAgent global opencode config.
# PowerShell twin of scripts/bootstrap.sh. See that script for the full docs.
#
# Usage:
#   .\scripts\bootstrap.ps1 [-VerifyOnly] [-Target DIR] [-RepoUrl URL] [-Branch NAME]

$ErrorActionPreference = "Stop"

if (-not $RepoUrl) {
    if ($env:DAVERAGENT_REPO_URL) { $RepoUrl = $env:DAVERAGENT_REPO_URL }
    else { $RepoUrl = "https://github.com/DaveR-ui/DaverAgent.git" }
}
if (-not $Target) {
    if ($env:XDG_CONFIG_HOME) { $Target = Join-Path $env:XDG_CONFIG_HOME "opencode" }
    else { $Target = Join-Path $HOME ".config/opencode" }
}

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path

function Write-Log([string]$m)  { Write-Host $m }
function Write-Warn2([string]$m) { Write-Host "WARN:  $m" -ForegroundColor Yellow }
function Die([string]$m)         { Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }

function Test-Layout([string]$Root) {
    $fail = $false
    foreach ($p in @("opencode.json", "AGENTS.md", "agents", "protocols", "workflows", "scripts")) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $p))) {
            Write-Warn2 "missing $p under $Root"
            $fail = $true
        }
    }
    if (Test-Path -LiteralPath (Join-Path $Root "agents/subagents")) {
        Write-Warn2 "legacy agents/subagents/ found; the flat layout is expected"
        $fail = $true
    }
    $cfg = Join-Path $Root "opencode.json"
    if (Test-Path -LiteralPath $cfg) {
        try { Get-Content -LiteralPath $cfg -Raw | ConvertFrom-Json | Out-Null }
        catch { Write-Warn2 "$cfg is not valid JSON"; $fail = $true }
    }
    return (-not $fail)
}

function Get-OriginUrl([string]$Root) {
    $out = & git -C $Root remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0) { return "" }
    return ([string]$out).Trim()
}

function ConvertTo-NormalizedUrl([string]$u) {
    # Normalize a git remote to "host/owner/repo" (lowercased) so https, ssh, and
    # scp-like forms compare equal.
    if (-not $u) { return "" }
    $s = $u.Trim()
    $s = $s -replace '^[A-Za-z][A-Za-z0-9+.-]*://', ''
    $s = $s -replace '^[^@/]+@', ''
    $s = $s -replace '^([^/:]+):', '$1/'
    $s = $s -replace '\.git$', ''
    $s = $s.TrimEnd('/')
    return $s.ToLowerInvariant()
}

function Test-OurInstall([string]$Root) {
    # True when $Root is a checkout/clone of this agent-system repo. Prefer the
    # normalized remote match; fall back to a structural marker so an SSH URL or
    # an origin alias is not misclassified as a foreign config (which would back
    # it up and re-clone, discarding local edits).
    if (-not (Test-Path -LiteralPath (Join-Path $Root ".git"))) { return $false }
    $normOrigin = ConvertTo-NormalizedUrl (Get-OriginUrl $Root)
    $normRepo   = ConvertTo-NormalizedUrl $RepoUrl
    if ($normOrigin -and ($normOrigin -eq $normRepo)) { return $true }
    if (-not (Test-Path -LiteralPath (Join-Path $Root "opencode.json"))) { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $Root "AGENTS.md")))     { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $Root "agents")))        { return $false }
    if (Test-Path -LiteralPath (Join-Path $Root "agents/subagents"))     { return $false }
    return [bool](Select-String -LiteralPath (Join-Path $Root "opencode.json") -Pattern '"agent-system"' -Quiet)
}

function Invoke-Clone([string]$Dest) {
    if ($Branch) { & git clone --branch $Branch $RepoUrl $Dest }
    else         { & git clone $RepoUrl $Dest }
    if ($LASTEXITCODE -ne 0) { Die "git clone failed" }
}

function Get-FullPath([string]$p) {
    try { return [System.IO.Path]::GetFullPath($p) } catch { return $p }
}

Write-Log "DaverAgent bootstrap"
Write-Log "  source : $SourceRoot"
Write-Log "  target : $Target"
Write-Log "  remote : $RepoUrl"
if ($VerifyOnly) { Write-Log "  mode   : verify-only (no writes)" }
Write-Log ""

# 1. Target is the source repo itself (running in-place): just verify.
if ((Test-Path -LiteralPath $Target) -and ((Get-FullPath $Target) -eq (Get-FullPath $SourceRoot))) {
    Write-Log "Target is the source repository; nothing to clone."
    if (Test-Layout $SourceRoot) { Write-Log "OK: layout is valid."; exit 0 }
    Die "layout check failed."
}

# 2. Target absent.
if (-not (Test-Path -LiteralPath $Target)) {
    if ($VerifyOnly) {
        Write-Log "would clone $RepoUrl -> $Target"
        if (Test-Layout $SourceRoot) { Write-Log "OK: source layout is valid; verify-only, no writes."; exit 0 }
        Die "source layout check failed."
    }
    Write-Log "Cloning $RepoUrl -> $Target ..."
    $parent = Split-Path -Parent $Target
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Invoke-Clone $Target
    Write-Log ""
    if (Test-Layout $Target) {
        Write-Log "OK: installed at $Target."
        Write-Log "Next:  cd `"$Target`"; bash tests/run-tests.sh"
        exit 0
    }
    Die "clone succeeded but layout check failed."
}

# 3. Target exists and is our clone -> update.
if (Test-OurInstall $Target) {
    if ($VerifyOnly) {
        Write-Log "would update existing clone at $Target (git pull --ff-only)"
        if (Test-Layout $Target) { Write-Log "OK: layout is valid; verify-only, no writes."; exit 0 }
        Die "layout check failed."
    }
    Write-Log "Updating existing clone at $Target ..."
    & git -C $Target pull --ff-only
    if ($LASTEXITCODE -ne 0) { Die "git pull failed (local changes?)" }
    Write-Log ""
    if (Test-Layout $Target) { Write-Log "OK: updated $Target."; exit 0 }
    Die "update succeeded but layout check failed."
}

# 4. Target exists but is NOT this clone -> back up, then clone fresh.
$Backup = "$Target.bak." + (Get-Date -Format "yyyyMMdd-HHmmss")
if ($VerifyOnly) {
    Write-Log "would back up $Target -> $Backup"
    Write-Log "would clone $RepoUrl -> $Target"
    if (Test-Layout $SourceRoot) { Write-Log "OK: source layout is valid; verify-only, no writes."; exit 0 }
    Die "source layout check failed."
}
Write-Log "Existing target is not a DaverAgent clone."
Write-Log "Backing up $Target -> $Backup ..."
Move-Item -LiteralPath $Target -Destination $Backup -Force
try {
    Invoke-Clone $Target
} catch {
    Write-Warn2 "clone failed; restoring backup"
    Move-Item -LiteralPath $Backup -Destination $Target -Force
    throw
}
Write-Log ""
if (Test-Layout $Target) {
    Write-Log "OK: installed at $Target (previous config backed up at $Backup)."
    Write-Log "Next:  cd `"$Target`"; bash tests/run-tests.sh"
    exit 0
}
Die "clone succeeded but layout check failed."
