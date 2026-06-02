# stop-gate.ps1
# Stop hook -- two layers:
#   1. HARD BLOCK: this session has unreviewed code changes (.claude/review-needed-<sid>.txt exists)
#                  -> output decision=block JSON. Forces code-reviewer dispatch.
#   2. SOFT NAG:   review marker absent but git has uncommitted changes
#                  -> output systemMessage JSON with an end-of-session checklist.
#                  Stop is allowed; the reminder is shown to the user.
#
# session_id from stdin scopes the marker check, so parallel chats don't lock each other out.

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $reader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $raw = $reader.ReadToEnd()
    $sid = $null
    if ($raw) {
        try {
            $payload = $raw | ConvertFrom-Json
            $sid = $payload.session_id
        } catch {}
    }
    if (-not $sid) { exit 0 }

    $sidShort = ($sid -replace '[^a-zA-Z0-9]', '').Substring(0, [Math]::Min(12, ($sid -replace '[^a-zA-Z0-9]', '').Length))
    if (-not $sidShort) { exit 0 }

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if (-not $projectDir) { $projectDir = (Get-Location).Path }

    # ---------- Layer 1: HARD BLOCK on unreviewed code changes ----------
    $marker = Join-Path $projectDir ".claude/review-needed-$sidShort.txt"
    if (Test-Path $marker) {
        $files = Get-Content $marker -Encoding UTF8 -ErrorAction SilentlyContinue | Where-Object { $_ -ne '' }
        $fileList = if ($files) { ($files | Select-Object -Unique) -join "`n  - " } else { '(no list)' }

        $reason = @"
[stop-gate HARD BLOCK] This session has unreviewed code changes. Stop blocked.

Pending review files (this session only):
  - $fileList

Required next steps:
  1. Dispatch the code-reviewer Sub-Agent.
  2. Stage 1 + Stage 2 must both pass.
  3. code-reviewer will delete .claude/review-needed-$sidShort.txt after passing.
  4. Stop is then unlocked.

If review is genuinely unnecessary (pure docs/config), run: rm .claude/review-needed-$sidShort.txt
"@
        $blockOut = @{
            decision = "block"
            reason = $reason
        } | ConvertTo-Json -Depth 5 -Compress
        [Console]::Out.Write($blockOut)
        exit 0
    }

    # ---------- Layer 2: SOFT NAG when uncommitted changes remain ----------
    Push-Location $projectDir
    $uncommittedCount = 0
    try {
        $statusOut = & git status --short 2>$null
        if ($statusOut) {
            $uncommittedCount = ($statusOut | Where-Object { $_ -ne '' } | Measure-Object).Count
        }
    } catch {} finally { Pop-Location }

    $checklist = @"
[stop-gate SOFT NAG] About to stop. End-of-session checklist (relay to user):
  - Is the task doc's "result" section filled in (done / failed / abandoned)?
  - Any uncommitted changes that should be committed or backed up?
  - Anything to write back into project docs (architecture change / new conventions)?
"@

    if ($uncommittedCount -gt 0) {
        $checklist = "[stop-gate SOFT NAG] About to stop with $uncommittedCount uncommitted change(s). " + $checklist.Substring($checklist.IndexOf("`n"))
    }

    $nagOut = @{
        systemMessage = $checklist
    } | ConvertTo-Json -Depth 5 -Compress
    [Console]::Out.Write($nagOut)
    exit 0
} catch {
    [Console]::Error.WriteLine("[stop-gate] hook internal error (stop allowed): " + $_.Exception.Message)
    exit 0
}
