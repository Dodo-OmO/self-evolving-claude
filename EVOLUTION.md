# EVOLUTION.md

毕业的反馈记录。从 `.claude/feedback/` 升级到 `CLAUDE.md` 或某个 Skill 的规则会移到这里，**保留追溯**——什么时候、因为什么反馈、写到了哪。这是工程系统"随用随长"的成长档案。

## 格式

每次执行升级追加一段：

```markdown
## YYYY-MM-DD：[规则一句话]

- **来源**：.claude/feedback/<category>.md（被强化 N 次）
- **升级到**：[CLAUDE.md / .claude/skills/<skill>/SKILL.md / .claude/agents/<agent>.md]
- **升级文案**：
  > [写进规则文件的具体那段]
- **触发反馈摘要**：
  - YYYY-MM-DD：一句话
  - YYYY-MM-DD：一句话
  - YYYY-MM-DD：一句话
```

## 规则演化历史（示例）

> 下面是一条**示范案例**，展示一条反馈如何从重复出现毕业成硬规则。真实使用时按你的项目积累替换。

## 2026-01-10：Windows 脚本（.bat/.cmd）改动必须保留 CRLF 行尾

- **来源**：.claude/feedback/tooling.md + debug.md（同根因多次强化）
- **升级到**：CLAUDE.md 协作纪律段
- **升级文案**：
  > 用 Edit/Write 改 .bat/.cmd 会把行尾规范化为 LF，Windows `cmd.exe` 遇 LF 行尾立即退出，导致脚本静默失效。改这类文件用显式 CRLF 写入（如 PowerShell `[System.IO.File]::WriteAllText` + `\r\n`），改完用 `ReadAllBytes` 核对 `0x0D 0x0A` 字节对。git 输出 `LF will be replaced by CRLF` 涉及 Windows-only 脚本时 = 执行级警告，必须停下核查。
- **触发反馈摘要**：
  - 2026-01-04：某启动脚本被改成 LF 后静默失效，排查耗时数小时
  - 2026-01-08：再次因行尾问题导致脚本不执行
  - 2026-01-10：确认根因并毕业为硬规则
