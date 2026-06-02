# check-evolution.ps1
# SessionStart hook -- on new session, check .claude/feedback accumulation and remind main agent

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $projectDir = $env:CLAUDE_PROJECT_DIR
    if (-not $projectDir) { $projectDir = (Get-Location).Path }

    $feedbackDir = Join-Path $projectDir '.claude/feedback'
    if (-not (Test-Path $feedbackDir)) { exit 0 }

    $files = Get-ChildItem $feedbackDir -Filter '*.md' -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'FEEDBACK-INDEX.md' -and $_.Name -ne 'README.md' }
    if (-not $files -or $files.Count -eq 0) { exit 0 }

    $hot = @()
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        $count = ([regex]::Matches($content, '(?m)^## ')).Count
        if ($count -ge 3) {
            $hot += "$($f.BaseName) ($count entries)"
        }
    }

    $totalFiles = $files.Count

    $msg = "[check-evolution] feedback library has $totalFiles category files."
    if ($hot.Count -gt 0) {
        $msg += "`n  WARN: the following categories have 3+ entries; consider dispatching evolution-runner this session:`n  - " + ($hot -join "`n  - ")
    }

    $payload = @{
        hookSpecificOutput = @{
            hookEventName = "SessionStart"
            additionalContext = $msg
        }
    } | ConvertTo-Json -Depth 5 -Compress
    [Console]::Out.Write($payload)
    exit 0
} catch {
    exit 0
}
