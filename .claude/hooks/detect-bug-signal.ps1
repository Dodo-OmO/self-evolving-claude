# detect-bug-signal.ps1
# PostToolUse hook (matcher: Bash|PowerShell) -- detect build/test failure signals.
# 命中白名单命令 (npm run build / npm test / npx jest) + 输出含强错误模式 -> 提醒主对话派 bug-fixer-agent.
# 不碰 tsc 单独命令 (由 pre-commit-check + tsc-baseline 管, 避免双触发).

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $reader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $raw = $reader.ReadToEnd()
    if (-not $raw) { exit 0 }
    $payload = $raw | ConvertFrom-Json

    # Only PostToolUse + Bash/PowerShell
    if ($payload.hook_event_name -ne 'PostToolUse') { exit 0 }
    $toolName = $payload.tool_name
    if ($toolName -ne 'Bash' -and $toolName -ne 'PowerShell') { exit 0 }

    $cmd = $payload.tool_input.command
    if (-not $cmd) { exit 0 }

    # 命令白名单 (避免任何 PowerShell/Bash 命令都被扫)
    $isBuildOrTest = $false
    if ($cmd -match 'npm(\.cmd)?\s+run\s+build') { $isBuildOrTest = $true }
    elseif ($cmd -match 'npm(\.cmd)?\s+test') { $isBuildOrTest = $true }
    elseif ($cmd -match 'npx\s+jest') { $isBuildOrTest = $true }
    if (-not $isBuildOrTest) { exit 0 }

    # 拿 tool_response 整体文本 (字段名跨版本可能不同, 整体 stringify 后做 grep 最稳)
    $respText = ''
    if ($payload.tool_response) {
        $respText = $payload.tool_response | ConvertTo-Json -Depth 10 -Compress
    }
    if (-not $respText) { exit 0 }

    # 强错误模式 (避免 npm install 中 "0 errors" / "found 0 vulnerabilities" 假阳性)
    $isFailure = $false
    if ($respText -match 'error TS\d+') { $isFailure = $true }              # tsc 真错误
    elseif ($respText -match 'Test Suites:\s*\d+\s*failed') { $isFailure = $true }  # jest 失败汇总
    elseif ($respText -match 'Tests:\s*\d+\s*failed') { $isFailure = $true }
    elseif ($respText -match 'npm\s+ERR!') { $isFailure = $true }           # npm 错误前缀
    elseif ($respText -match 'Build failed') { $isFailure = $true }         # tsup/esbuild
    elseif ($respText -match 'ELIFECYCLE') { $isFailure = $true }           # npm script 非零退出
    elseif ($respText -match 'SyntaxError') { $isFailure = $true }
    if (-not $isFailure) { exit 0 }

    $msg = "[detect-bug-signal] 检测到 build/test 失败信号。建议先派 bug-fixer-agent 分析根因再动手修复，不要凭印象直接改（单行 typo / 显而易见的笔误可直接修）。"
    $reminder = @{
        hookSpecificOutput = @{
            hookEventName = "PostToolUse"
            additionalContext = $msg
        }
    } | ConvertTo-Json -Depth 5 -Compress
    [Console]::Out.Write($reminder)
    exit 0
} catch {
    exit 0
}
