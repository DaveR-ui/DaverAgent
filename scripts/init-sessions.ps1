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

& (Join-Path $PSScriptRoot "bootstrap-opencode-structure.ps1") @PSBoundParameters
