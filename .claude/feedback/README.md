# Feedback 库

Steering Loop 的反馈记录区。用户每次纠正 / 给反馈，`feedback-observer` Sub-Agent 会**静默记录**到这里对应类目文件，主对话不打断。这是工程系统"随用随长"的入口。

## 类目文件命名

按"反馈本质"归类，不按时间。例如：

- `coding-style.md` — 命名 / 结构 / 风格 / 注释
- `task-flow.md` — 协作流程（一步一改、先对齐、任务记录路径）
- `verbosity.md` — 罗嗦 / 废话 / 没说人话
- `tooling.md` — 工具使用（用对工具、别 cd、别批量）
- `harness-system.md` — 工程系统本身的使用方式（hook / agent / skill）
- `domain-<x>.md` — 你的项目领域知识（按需自建）

每条反馈一个 `## ` 二级标题段。

> ⚠️ **格式铁律**：check-evolution hook 按 `## ` 行数统计条数，所以条目内的元数据字段（信号类型 / 归并键 / 场景 / 规则等）一律用 `**bold**` 行，**绝不用 `## `**，否则虚增条数、毕业判定失真。条目格式见 `_example-task-flow.md`。

## 进化路径（四层）

1. **记录**（feedback-observer）：反馈 → 写对应类目文件
2. **毕业**（evolution-runner，同类 ≥3 条）：升级为 Skill / CLAUDE.md 正式规则
3. **优化**（同 Skill 长期被批）：提议优化该 Skill
4. **创建**（反复出现但无 Skill 覆盖）：提议新 Skill

每层都需**用户确认**才执行，不自动改规则。

## 归并键去重

见 `_keys.md`。feedback-observer 写入前先选**最匹配的现有键**；同键累加（更新日期 + 加一行 `**重现于 ...**`）而非新建——这样 evolution-runner 按键聚合计数判"≥3 次"才准。铁律：**先复用，后新增**，别造近义键。

## 不要把任务记录写这里

任务记录 → 你的任务文档目录。本目录只存"经验教训"，不存"做了什么"。
