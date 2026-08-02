<#
.SYNOPSIS
    Dumb HTTP helper for the opencode session-recovery protocol.
.DESCRIPTION
    Wraps the opencode session API as sub-commands. Does HTTP and prints JSON
    to stdout. No business logic lives here; the recovery flow is defined in
    .opencode/protocols/session-recovery.md.

    Auth: HTTP Basic. Password comes ONLY from the OPENCODE_SERVER_PASSWORD
    env var (never from CLI args, never logged). Optional env vars:
    OPENCODE_SERVER_URL (default http://127.0.0.1:4096) and
    OPENCODE_SERVER_USERNAME (default opencode).

    Sub-commands:
      health                         GET  /global/health
      list                           GET  /session
      status                         GET  /session/status
      inspect <id>                   GET  /session/:id
      children <id>                  GET  /session/:id/children
      abort <id>                     POST /session/:id/abort
      messages <id> [limit]          GET  /session/:id/message?limit=N (default 20)
      todo <id>                      GET  /session/:id/todo
      diff <id> [messageID]          GET  /session/:id/diff[?messageID=<msgID>]
      resume <id> [--fork-at <msg>]  POST /session {parentID} or POST /session/:id/fork {messageID}

    Exit codes: 0 success, 2 missing password, 3 HTTP 4xx/5xx, 4 network, 5 bad usage.
.EXAMPLE
    $env:OPENCODE_SERVER_PASSWORD = 'secret'
    .\session-recover.ps1 status
.EXAMPLE
    .\session-recover.ps1 resume ses_abc123 --fork-at msg_xyz
#>
param(
    [Parameter(Position=0)][string]$Command,
    [Parameter(Position=1, ValueFromRemainingArguments=$true)][object[]]$Rest
)

$ErrorActionPreference = 'Stop'

function Get-BaseUrl {
    if ($env:OPENCODE_SERVER_URL) { return $env:OPENCODE_SERVER_URL.TrimEnd('/') }
    return 'http://127.0.0.1:4096'
}

function Get-AuthHeader {
    $pass = $env:OPENCODE_SERVER_PASSWORD
    if (-not $pass) { [Console]::Error.WriteLine('ERROR: OPENCODE_SERVER_PASSWORD env var is required'); exit 2 }
    $user = $env:OPENCODE_SERVER_USERNAME
    if (-not $user) { $user = 'opencode' }
    return 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${user}:${pass}"))
}

function Exit-OnError($Err) {
    $ex = $Err.Exception
    if ($ex -is [System.Net.WebException] -and $null -ne $ex.Response) {
        $body = ''
        try { $r = New-Object IO.StreamReader($ex.Response.GetResponseStream()); $body = $r.ReadToEnd(); $r.Close() } catch {}
        if ($body.Length -gt 500) { $body = $body.Substring(0, 500) }
        [Console]::Error.WriteLine("HTTP $([int]$ex.Response.StatusCode) - $body")
        exit 3
    }
    [Console]::Error.WriteLine($ex.Message)
    exit 4
}

function Invoke-Get([string]$Path) {
    try { (Invoke-RestMethod -Method Get -Uri ((Get-BaseUrl) + $Path) -Headers @{ Authorization = (Get-AuthHeader) }) | ConvertTo-Json -Depth 10 }
    catch { Exit-OnError $_ }
}

function Invoke-Post([string]$Path, [hashtable]$Body) {
    $p = @{ Method = 'Post'; Uri = ((Get-BaseUrl) + $Path); Headers = @{ Authorization = (Get-AuthHeader) }; ContentType = 'application/json' }
    if ($Body) { $p['Body'] = ($Body | ConvertTo-Json -Compress) }
    try {
        $resp = Invoke-WebRequest @p
        if ($resp.Content) { $resp.Content } else { @{ ok = $true; status = [int]$resp.StatusCode } | ConvertTo-Json }
    } catch { Exit-OnError $_ }
}

function Get-Id {
    if ($Rest.Count -ge 1 -and $Rest[0]) { return [string]$Rest[0] }
    [Console]::Error.WriteLine("ERROR: '$Command' requires a session id."); exit 5
}

switch ($Command) {
    'health'   { Invoke-Get '/global/health' }
    'list'     { Invoke-Get '/session' }
    'status'   { Invoke-Get '/session/status' }
    'inspect'  { $id = Get-Id; Invoke-Get "/session/$id" }
    'children' { $id = Get-Id; Invoke-Get "/session/$id/children" }
    'abort'    { $id = Get-Id; Invoke-Post "/session/$id/abort" $null }
    'messages' {
        $id = Get-Id
        $limit = 20
        if ($Rest.Count -ge 2 -and ([string]$Rest[1]) -match '^\d+$') { $limit = [int]$Rest[1] }
        Invoke-Get "/session/$id/message?limit=$limit"
    }
    'todo'     { $id = Get-Id; Invoke-Get "/session/$id/todo" }
    'diff'     {
        $id = Get-Id
        $path = "/session/$id/diff"
        if ($Rest.Count -ge 2 -and $Rest[1]) { $path += '?messageID=' + [uri]::EscapeDataString([string]$Rest[1]) }
        Invoke-Get $path
    }
    'resume'   {
        $id = Get-Id
        $forkAt = $null
        for ($i = 1; $i -lt $Rest.Count; $i++) { if ([string]$Rest[$i] -eq '--fork-at' -and ($i + 1) -lt $Rest.Count) { $forkAt = [string]$Rest[$i + 1] } }
        if ($forkAt) { Invoke-Post "/session/$id/fork" @{ messageID = $forkAt } } else { Invoke-Post '/session' @{ parentID = $id } }
    }
    default {
        [Console]::Error.WriteLine("ERROR: unknown sub-command '$Command'. Valid: health, list, status, inspect, children, abort, messages, todo, diff, resume")
        exit 5
    }
}
