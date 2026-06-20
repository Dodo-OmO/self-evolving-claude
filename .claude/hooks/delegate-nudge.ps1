# delegate-nudge.ps1
# 让"该委派"从软规则变成在干活当下的轻提醒（中档·提醒，不阻断）。
# 双触发点：
#   1. UserPromptSubmit: 新一轮用户消息 -> 清零本轮主对话 Read 计数
#   2. PostToolUse: 只看主对话自己（agent_id=main）的工具调用
#        - Task/Agent (主对话派了sub-agent) -> 计数清零，重新开始
#        - Read (文件原文进上下文) -> 计数 +1；命中 5 / 10 -> 注入软提醒
#      subagent 自己的 Read 不计（按 agent_id / agent_type 区分；同 session_id 但身份字段不同）。
#      只计 Read，不计 Grep/Glob（轻量 scouting，主对话自己做正当）。
#
# 状态文件（per-session）：.claude/.delegate-read-count-<sid>.txt

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $reader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $raw = $reader.ReadToEnd()
    if (-not $raw) { exit 0 }
    $payload = $raw | ConvertFrom-Json

    $sid = $payload.session_id
    if (-not $sid) { exit 0 }
    $sidClean = ($sid -replace '[^a-zA-Z0-9]', '')
    if (-not $sidClean) { exit 0 }
    $sidShort = $sidClean.Substring(0, [Math]::Min(12, $sidClean.Length))

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if (-not $projectDir) { $projectDir = (Get-Location).Path }

    $countFile = Join-Path $projectDir ".claude/.delegate-read-count-$sidShort.txt"
    $hookEvent = $payload.hook_event_name

    # ----- 触发点 1: UserPromptSubmit -> 新一轮，清零 -----
    if ($hookEvent -eq 'UserPromptSubmit') {
        if (Test-Path $countFile) { Remove-Item $countFile -Force -ErrorAction SilentlyContinue }
        exit 0
    }

    if ($hookEvent -ne 'PostToolUse') { exit 0 }

    # ----- 区分主对话 vs subagent：非 main 身份一律跳过（subagent 的读不计）-----
    $agentType = $payload.agent_type
    $agentId = $payload.agent_id
    $isSubagent = ("$agentType" -ne '') -or ("$agentId" -ne '' -and "$agentId" -ne 'main')
    if ($isSubagent) { exit 0 }

    $toolName = $payload.tool_name

    # 主对话派了sub-agent -> 已委派，计数清零重新开始
    if ($toolName -eq 'Task' -or $toolName -eq 'Agent') {
        if (Test-Path $countFile) { Remove-Item $countFile -Force -ErrorAction SilentlyContinue }
        exit 0
    }

    # 只计 Read
    if ($toolName -ne 'Read') { exit 0 }

    $count = 0
    if (Test-Path $countFile) {
        $existing = Get-Content $countFile -Raw -ErrorAction SilentlyContinue
        if ($existing) { try { $count = [int]($existing.Trim()) } catch { $count = 0 } }
    }
    $count++
    Set-Content -Path $countFile -Value $count -Encoding UTF8

    # 命中阈值 -> 软提醒（5 / 10 各一次，之后静默）
    if ($count -eq 5 -or $count -eq 10) {
        $msg = "[delegate-nudge] 本轮主对话已自己 Read $count 个文件。若这是铺开式调研/通读/摸排，按默认委派：派 1 个 Explore sub-agent去读、只回摘要，别让文件原文灌爆主上下文（派前按难度配模型档；要并行多块走 parallel-exec 过额度闸）。若是针对性核实（查某条规则/代码行、核实子助手结论、就读这几个）-> 属正当直接读，忽略本提醒继续。"
        $reminder = @{
            hookSpecificOutput = @{
                hookEventName = "PostToolUse"
                additionalContext = $msg
            }
        } | ConvertTo-Json -Depth 5 -Compress
        [Console]::Out.Write($reminder)
    }

    exit 0
} catch {
    exit 0
}
