# mark-review-needed.ps1
# PostToolUse hook (matcher: Edit|Write|MultiEdit|NotebookEdit)
# Append edited file to .claude/review-needed-<session_id>.txt (per-session marker).
# Pairs with stop-gate, which only blocks on its OWN session marker -- avoids cross-chat lockouts.

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $reader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $raw = $reader.ReadToEnd()
    if (-not $raw) { exit 0 }
    $payload = $raw | ConvertFrom-Json

    $filePath = $payload.tool_input.file_path
    if (-not $filePath) { exit 0 }

    # Skip non-code files (docs/config/deps) -- only code changes need review gating.
    $skipPatterns = @(
        '\.claude[\\/]feedback[\\/]',
        '\.claude[\\/]hooks[\\/]',
        '\.claude[\\/]agents[\\/]',
        '\.claude[\\/]skills[\\/]',
        '\.claude[\\/]review-needed',
        '\.claude[\\/]release-marker',
        'EVOLUTION\.md',
        '\.md$',
        '\.json$',
        'node_modules',
        'dist[\\/]'
    )
    foreach ($pattern in $skipPatterns) {
        if ($filePath -match $pattern) { exit 0 }
    }

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if (-not $projectDir) { $projectDir = (Get-Location).Path }

    # session_id from hook input -- short prefix is enough for filename
    $sid = $payload.session_id
    if (-not $sid) { $sid = 'unknown' }
    $sidShort = ($sid -replace '[^a-zA-Z0-9]', '').Substring(0, [Math]::Min(12, ($sid -replace '[^a-zA-Z0-9]', '').Length))
    if (-not $sidShort) { $sidShort = 'unknown' }

    $marker = Join-Path $projectDir ".claude/review-needed-$sidShort.txt"
    Add-Content -Path $marker -Value $filePath -Encoding UTF8
    exit 0
} catch {
    exit 0
}
