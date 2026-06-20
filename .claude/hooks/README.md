# Hooks — 确定性卡口

这套 hook 给 Claude Code 加**确定性护栏**（不依赖模型自觉，由 harness 在固定时机强制执行）。

实现语言是 PowerShell。装了 [PowerShell 7+（pwsh，跨平台）](https://github.com/PowerShell/PowerShell) 后，**Windows / macOS / Linux 都能跑**——脚本只用了 .NET 标准 API + 跨平台 cmdlet（`Join-Path` / `git` / `npx`），不含 Windows 专有调用。

## 接线（`.claude/settings.json`）

每个 hook 挂到对应生命周期事件。示例：

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "pwsh -NoProfile -File \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-evolution.ps1\"" }] }
    ],
    "UserPromptSubmit": [
      { "hooks": [
        { "type": "command", "command": "pwsh -NoProfile -File \"$CLAUDE_PROJECT_DIR/.claude/hooks/detect-feedback-signal.ps1\"" },
        { "type": "command", "command": "pwsh -NoProfile -File \"$CLAUDE_PROJECT_DIR/.claude/hooks/delegate-nudge.ps1\"" }
      ] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "pwsh -NoProfile -File \"$CLAUDE_PROJECT_DIR/.claude/hooks/pre-commit-check.ps1\"" }] }
    ],
    "PostToolUse": [
      { "matcher": "Bash|PowerShell", "hooks": [{ "type": "command", "command": "pwsh -NoProfile -File \"$CLAUDE_PROJECT_DIR/.claude/hooks/detect-bug-signal.ps1\"" }] },
      { "matcher": "Edit|Write|MultiEdit|NotebookEdit", "hooks": [{ "type": "command", "command": "pwsh -NoProfile -File \"$CLAUDE_PROJECT_DIR/.claude/hooks/mark-review-needed.ps1\"" }] },
      { "matcher": "Read|Task|Agent", "hooks": [{ "type": "command", "command": "pwsh -NoProfile -File \"$CLAUDE_PROJECT_DIR/.claude/hooks/delegate-nudge.ps1\"" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "pwsh -NoProfile -File \"$CLAUDE_PROJECT_DIR/.claude/hooks/stop-gate.ps1\"" }] }
    ]
  }
}
```

## 各 hook 作用

| hook | 事件 | 作用 |
|---|---|---|
| `check-evolution` | SessionStart | 开局检查 `.claude/feedback/` 累积，某类目 ≥3 条 → 提示派 evolution-runner |
| `detect-feedback-signal` | UserPromptSubmit | 用户消息含修正信号（见 feedback-signals.txt）→ 提示派 feedback-observer |
| `detect-bug-signal` | PostToolUse(Bash) | build/test 输出含失败模式 → 提示派 bug-fixer-agent |
| `mark-review-needed` | PostToolUse(Edit/Write) | 代码改动 → 写 per-session 审查标记（文档/配置跳过） |
| `stop-gate` | Stop | ① 有未审代码改动 → **硬拦截**强制 code-reviewer；② 否则收尾清单**软提醒** |
| `pre-commit-check` | PreToolUse(Bash) | `git commit` 前跑 tsc，错误数超 baseline 才拦（baseline 自动维护、只降不升） |
| `delegate-nudge` | PostToolUse(Read/Task/Agent) + UserPromptSubmit | 主对话自己 Read 文件数超阈值（5/10）→ 软提醒"铺开式调研该派 sub-agent 收摘要"；按 agent 身份区分（sub-agent 的读不计），派 Task / 换轮清零。只提醒不阻断 |

**per-session 隔离**：marker 文件按 `session_id` 命名，多个并行会话互不锁死。

## 配套文件

- `feedback-signals.txt`：修正信号词表，按你的习惯自定义
- `tsc-baseline.txt`：pre-commit-check 首次运行自动生成（记录已知 tsc 错误数），无需手建
- `TSC_CHECK_DIR`（环境变量，可选）：代码不在项目根时，指向真正的代码目录

## 未包含的 hook（项目专属示例）

原项目还有几个深度绑定具体环境的 hook，**未纳入通用模板**，仅说明机制供参考——按需自建：

- **任务文档存在性检查**：首次写代码时若当天还没建任务文档 → 提醒先建后干（硬编码文档目录）
- **备份排除检查**：备份命令必须排除依赖目录 + 敏感凭据文件，否则拦截（绑定具体备份路径）
- **effort 切换提醒**：审查通过 / 进入收尾时，提示调整推理档位（绑定具体工作流节奏）
