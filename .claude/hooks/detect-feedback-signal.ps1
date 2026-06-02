# detect-feedback-signal.ps1
# UserPromptSubmit hook -- detect correction keywords in the user prompt
# Signal list lives in .claude/hooks/feedback-signals.txt (UTF-8 — one keyword per line, '#' comments).
# Customize that file with your own correction phrases.

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $reader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $raw = $reader.ReadToEnd()
    if (-not $raw) { exit 0 }
    $payload = $raw | ConvertFrom-Json
    $prompt = $payload.prompt
    if (-not $prompt) { exit 0 }

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if (-not $projectDir) { $projectDir = (Get-Location).Path }

    $signalsFile = Join-Path $projectDir '.claude/hooks/feedback-signals.txt'
    if (-not (Test-Path $signalsFile)) { exit 0 }

    $signals = Get-Content $signalsFile -Encoding UTF8 | Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

    $hit = $false
    foreach ($sig in $signals) {
        if ($prompt.Contains($sig)) {
            $hit = $true
            break
        }
    }

    if (-not $hit) { exit 0 }

    $msg = "[detect-feedback-signal] Correction signal detected in user prompt. After this turn, dispatch feedback-observer Sub-Agent to capture the feedback into .claude/feedback/ category file. Tell the user (in Chinese): 检测到修正信号, 已记。"
    $reminder = @{
        hookSpecificOutput = @{
            hookEventName = "UserPromptSubmit"
            additionalContext = $msg
        }
    } | ConvertTo-Json -Depth 5 -Compress
    [Console]::Out.Write($reminder)
    exit 0
} catch {
    exit 0
}
