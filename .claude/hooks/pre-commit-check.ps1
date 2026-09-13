# pre-commit-check.ps1
# PreToolUse hook (matcher: Bash) -- before git commit, run the project's type check and compare to baseline.
# Uses `npm run typecheck` when package.json defines that script (so a multi-tsconfig project -- root + electron +
# worker etc. -- gets every tsconfig checked); otherwise falls back to `tsc --noEmit`, which only sees the root tsconfig.
# Baseline lives in .claude/tsc-baseline.txt (a single integer = known error count).
# First run: record baseline, do not block.
# Later runs: block only when new error count > baseline.
# When error count drops, auto-lower the baseline so it cannot creep back up.

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $reader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $raw = $reader.ReadToEnd()
    if (-not $raw) { exit 0 }
    $payload = $raw | ConvertFrom-Json
    $cmd = $payload.tool_input.command
    if (-not $cmd) { exit 0 }
    if ($cmd -notmatch 'git\s+commit') { exit 0 }

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if (-not $projectDir) { $projectDir = (Get-Location).Path }

    $baselineFile = Join-Path $projectDir '.claude/tsc-baseline.txt'

    # tsc runs in the code directory. Default = project root (code and .claude in same dir).
    # If your code lives in a different folder (e.g. monorepo package), set env TSC_CHECK_DIR.
    $codeDir = if ($env:TSC_CHECK_DIR) { $env:TSC_CHECK_DIR } else { $projectDir }

    # Prefer the project's own `typecheck` script (covers every tsconfig); plain tsc only checks the root one.
    $hasTypecheck = $false
    try {
        $pkgFile = Join-Path $codeDir 'package.json'
        if (Test-Path $pkgFile) {
            $pkg = Get-Content $pkgFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($pkg.scripts -and $pkg.scripts.typecheck) { $hasTypecheck = $true }
        }
    } catch {}

    Push-Location $codeDir
    try {
        if ($hasTypecheck) { $tscOut = & npm run typecheck 2>&1 | Out-String }
        else { $tscOut = & npx --no-install tsc --noEmit 2>&1 | Out-String }
        $tscExit = $LASTEXITCODE
    } catch {
        $tscOut = $_.Exception.Message
        $tscExit = 1
    } finally {
        Pop-Location
    }

    $errCount = ([regex]::Matches($tscOut, ': error TS')).Count

    # If tsc exited 0, errCount should be 0
    if ($tscExit -eq 0) { $errCount = 0 }

    $baseline = -1
    if (Test-Path $baselineFile) {
        $rawBaseline = (Get-Content $baselineFile -Encoding UTF8 -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
        if ($rawBaseline -match '^\d+$') { $baseline = [int]$rawBaseline }
    }

    if ($baseline -lt 0) {
        Set-Content -Path $baselineFile -Value $errCount -Encoding UTF8
        [Console]::Error.WriteLine("[pre-commit-check] baseline established: $errCount tsc errors. Future commits blocked only if errors exceed this. Edit .claude/tsc-baseline.txt manually to reset.")
        exit 0
    }

    if ($errCount -gt $baseline) {
        $delta = $errCount - $baseline
        [Console]::Error.WriteLine("[pre-commit-check] BLOCKED. tsc reports $errCount errors (baseline: $baseline, +$delta new). Fix the new errors before commit:")
        [Console]::Error.WriteLine($tscOut)
        exit 2
    }

    if ($errCount -lt $baseline) {
        Set-Content -Path $baselineFile -Value $errCount -Encoding UTF8
        [Console]::Error.WriteLine("[pre-commit-check] tsc baseline lowered: $baseline -> $errCount.")
    }

    exit 0
} catch {
    [Console]::Error.WriteLine("[pre-commit-check] hook internal error (passed through): " + $_.Exception.Message)
    exit 0
}
