[CmdletBinding()]
param(
    [string]$TargetRoot = $(Join-Path $env:USERPROFILE ".config\opencode"),
    [string]$HumanId = $env:USERNAME,
    [string]$ProjectId,
    [string]$RepoPath
)

& (Join-Path $PSScriptRoot "bootstrap-opencode-structure.ps1") `
    -TargetRoot $TargetRoot `
    -HumanId $HumanId `
    -ProjectId $ProjectId `
    -RepoPath $RepoPath `
    -VerifyOnly `
    -FailIfMissing
