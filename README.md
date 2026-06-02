# Claude Self-Evolving Harness · 自进化开发工程系统

**写在前面 · A note from a non-technical author**

我是一个**来自中国的女性影视从业者**，也是个对代码**完全零基础的文科生**。这套工程系统，是我用来迭代自己个人项目的"脚手架"。

之所以堆了这么多道审查关卡，是因为我没法像工程师那样一眼看穿代码里的问题——于是我把"严谨"交给流程：让几个 AI 子助手互相审查、唱反调、记住每一次踩过的坑，替我守住那些**我自己看不见的雷**。它谈不上多专业，但让一个不懂代码的人，也能一点点把自己的项目认真养大。**欢迎各位大佬拍砖、指点。** 🌱

> *I'm a woman from China, working in the film & TV industry — and a humanities major with **zero coding background**. This engineering system is the "scaffolding" I use to iterate on my own personal project.*
>
> *It's stacked with this many review gates for one simple reason: I can't spot code-level problems at a glance the way an engineer can. So I hand "rigor" over to the process — a handful of AI sub-agents that review each other, play devil's advocate, and remember every lesson learned, guarding the landmines I can't see myself. It's nothing fancy, but it lets someone who can't code still raise a project with real care. **Feedback and criticism from seasoned developers are genuinely welcome.*** 🌱

一套给 **Claude Code** 的"自进化开发工程系统"。用 **sub-agents + hooks + feedback 进化环**，让 AI 协作开发**既有确定性护栏、又能随用随长**——你纠正一次，它记住一类，累积到一定次数自动"毕业"成硬规则。把 `.claude/` + `CLAUDE.md` 放进你的项目根即可用，按需裁剪。

> *A self-evolving engineering harness for **Claude Code**: sub-agents + hooks + a feedback-evolution loop that give AI-assisted development **deterministic guardrails** while letting your rules **grow as you use them** — correct it once, it remembers the whole class of mistake, and after enough recurrences it "graduates" into a hard rule. Drop `.claude/` + `CLAUDE.md` into your project root and go; trim as needed. Docs are in Chinese; the system itself is language-agnostic.*

## 📦 这是什么 / 不是什么 · What it is (and isn't)

这是一套**叠加到你自己项目上的"工程系统层"**——把 `.claude/` + `CLAUDE.md` 拷进**你现有的代码项目**，它就给你的开发流程加上审查 / 调试 / 进化的护栏。

**本仓库只含"工程系统层"本身**（agents / hooks / skills / 规则），**不含被它管理的项目代码**。所以下面这些反复出现的词，指的都是**你自己项目里的东西**，不是本仓库自带——单独浏览本仓库时心里有数：

| 文中出现的词 | 指的是 |
|---|---|
| 项目代码 / 代码库 | 你自己项目的源代码（你把 `.claude/` 拷进去的那个项目） |
| 项目背景文档 / 架构文档 | 你为自己项目写的架构 / 设计说明（需你自备，本模板不含；可选但推荐） |
| 任务文档 | 你的任务记录文件（放哪、什么格式由你定） |
| 项目体检 | 对"你的代码库 + 这套工程系统"做的全局扫描 |

一句话：本仓库给的是**预留好接口的工程方法论骨架**，套到你项目上，这些"接口"才各有所指。

> *This is an **"engineering-system layer" you drop onto your own project** — copy `.claude/` + `CLAUDE.md` into **your existing codebase** and it adds review / debugging / evolution guardrails to your workflow.*
>
> *This repo contains **only the engineering-system layer itself** (agents / hooks / skills / rules), **not the project code it manages**. So the recurring terms below all refer to **things in your own project**, not something shipped here — worth keeping in mind when browsing this repo alone:*
>
> | Term you'll see | What it means |
> |---|---|
> | project code / codebase | your own project's source (the one you copy `.claude/` into) |
> | project background / architecture docs | the architecture / design notes you write for your project (bring your own; not included, optional but recommended) |
> | task doc | your task-tracking file (location and format are up to you) |
> | project check-up | a global scan over "your codebase + this engineering system" |
>
> *In one line: this repo gives you a **methodology skeleton with interfaces left open** — those "interfaces" only get their meaning once you fit it onto your project.*

## 它解决什么问题 · What it solves

| 痛点 | 这套系统的解法 |
|---|---|
| AI 改代码没护栏、容易引入回归 | **两阶段代码审查**（code-reviewer）+ 提交前 **tsc 卡口**（pre-commit-check hook）+ 未审改动**不让 stop**（stop-gate hook） |
| AI 拍脑门下大方案 | 大改动 v1 先过 **devil-advocate 唱反调内审**，消化问题再落地 |
| AI 反复犯同一个错 | **Steering Loop 进化环**：纠正 → feedback-observer 记录 → 累积 ≥3 次 → evolution-runner 提议毕业 → 你确认 → 升级成硬规则 |
| 调 bug 靠猜、改了又坏 | **bug-fixer 四阶段调试法**：证据 → 模式 → 假设 → 修复，一次只改一处，三层验证 |
| 长任务上下文丢失 | **任务文档当外置大脑** + 分章节 checkpoint，重启/压缩能续 |
| "验证通过"是空话 | **验证证据格式**硬规则：报通过必贴 build 输出 / 测试 PASS 数 / 实测结果 |

> | Pain point | How this system handles it |
> |---|---|
> | AI edits code with no guardrails, easily introduces regressions | **Two-stage code review** (code-reviewer) + a pre-commit **tsc gate** (pre-commit-check hook) + **no stop** on unreviewed changes (stop-gate hook) |
> | AI proposes big plans off the top of its head | Big changes get a **devil-advocate review** (v1 first), then land after digesting the objections |
> | AI repeats the same mistake | **Steering Loop**: correction → feedback-observer records it → ≥3 recurrences → evolution-runner proposes "graduation" → you confirm → it becomes a hard rule |
> | Debugging by guessing, fixes that break things again | **bug-fixer four-stage method**: evidence → pattern → hypothesis → fix; change one thing at a time, verify on three layers |
> | Long tasks lose context | **Task doc as external brain** + chapter checkpoints, so a restart/compaction can resume |
> | "Verified" as an empty word | A **proof-of-verification rule**: claiming success requires pasting build output / test PASS counts / actual results |

## 核心机制 · Core mechanics

**Steering Loop（让系统随用随长）**
```
用户纠正 → feedback-observer 记入 .claude/feedback/（泛化成规则，按归并键去重）
  → 同类累积 ≥3 次 → evolution-runner 识别毕业候选
  → 用户确认 → 升级进 CLAUDE.md / Skill 硬规则 → 移入 EVOLUTION.md 留痕
```

**双自审闸**：方案阶段有 `devil-advocate`（先反驳再执行），实现阶段有 `code-reviewer`（两阶段：功能合规 + 代码质量）。

> ***Steering Loop (how the system grows as you use it)***
> ```
> user correction → feedback-observer records into .claude/feedback/ (generalized into a rule, de-duped by merge key)
>   → ≥3 recurrences of a kind → evolution-runner spots a graduation candidate
>   → you confirm → promoted into CLAUDE.md / a Skill as a hard rule → moved to EVOLUTION.md for traceability
> ```
>
> ***Two self-review gates***: at the planning stage, `devil-advocate` (object first, then act); at the implementation stage, `code-reviewer` (two stages: functional compliance + code quality).

## 组成 · What's inside

```
├── CLAUDE.md                  工程"宪法"：价值观 / 自主模式 / 派发规则 / 实操纪律 / Steering Loop
│                              The "constitution": values / autonomous mode / dispatch rules / discipline / Steering Loop
├── .claude/                   ← 整个目录拷进你项目根即可，内部引用都按 .claude/... 写好了
│                              Copy this whole dir into your project root; internal references already use .claude/...
│   ├── agents/
│   │   ├── code-reviewer      两阶段代码审查（5 档严重度）/ two-stage code review (5 severity levels)
│   │   ├── devil-advocate     方案唱反调内审（7 维度）/ devil's-advocate plan review (7 dimensions)
│   │   ├── bug-fixer-agent    四阶段系统性调试 / four-stage systematic debugging
│   │   ├── feedback-observer  把纠正泛化成规则、写入 feedback 库 / generalize corrections into rules
│   │   ├── evolution-runner   识别毕业候选、生成升级建议 / spot graduation candidates, propose upgrades
│   │   └── block-worker       并行执行里的单块实现 worker / single-block worker for parallel execution
│   ├── skills/
│   │   ├── bug-fixer          四阶段调试方法论 / four-stage debugging methodology
│   │   ├── parallel-exec      切块并行执行（准入闸 + 切块契约）/ chunked parallel execution
│   │   └── project-iteration  迭代主流程（串起所有组件）/ main iteration flow (ties all components together)
│   ├── hooks/                 6 个确定性卡口（PowerShell，pwsh 跨平台）+ README / 6 deterministic gates (PowerShell)
│   └── feedback/              反馈库（机制说明 + 归并键表 + 示范条目）/ feedback library (mechanism + merge keys + sample)
├── EVOLUTION.md               规则毕业追溯 / rule-graduation trace
├── scripts/                   check-secrets.ps1（推送前守卫：内容+作者邮箱+悬空对象 三关）+ 模板
│                              pre-push guard: file content + commit-author email + dangling-object checks
└── README.md / LICENSE / .gitignore / .gitattributes
```

> 📌 组件会随迭代增减，上面的结构图**以仓库实际文件为准**（每次发版同步时一并更新，不依赖手记）。
>
> *📌 Components change across iterations; the tree above **follows the repo's actual files** (synced on each release, not kept by hand).*

## 怎么用 · How to use

1. 把本仓库的 `.claude/` 目录和 `CLAUDE.md` 整个拷进你自己项目的根目录——结构即插即用，无需改路径（agent / skill / hook 内部引用都按 `.claude/...` 写好了）。
2. 装 [PowerShell 7+（pwsh）](https://github.com/PowerShell/PowerShell)——hook 是 PowerShell 脚本，pwsh 在 Windows / macOS / Linux 都能跑。
3. 在 `.claude/settings.json` 里把 hook 接到对应事件（接线示例见 `hooks/README.md`）。
4. 按 `CLAUDE.md` 的价值观 + 派发规则协作；按 `skills/project-iteration` 跑你的迭代流程。
5. 自定义：`hooks/feedback-signals.txt`（你的修正口头禅）、`feedback/_keys.md`（你的归并键）会随项目慢慢长出来。

> 1. *Copy this repo's `.claude/` directory and `CLAUDE.md` into your own project root — plug-and-play, no path edits needed (agent / skill / hook references already use `.claude/...`).*
> 2. *Install [PowerShell 7+ (pwsh)](https://github.com/PowerShell/PowerShell) — the hooks are PowerShell scripts, and pwsh runs on Windows / macOS / Linux.*
> 3. *Wire the hooks to their events in `.claude/settings.json` (see `hooks/README.md` for wiring examples).*
> 4. *Collaborate per the values + dispatch rules in `CLAUDE.md`; run your iteration flow via `skills/project-iteration`.*
> 5. *Customize: `hooks/feedback-signals.txt` (your correction catchphrases) and `feedback/_keys.md` (your merge keys) will grow with your project over time.*

> hook 用的语言、tsc/npm 卡口默认面向 **Node/TypeScript** 项目。其它技术栈把 `pre-commit-check` / `detect-bug-signal` 里的编译 / 测试命令换成你的即可，方法论本身与语言无关。
>
> *The hook language and the tsc/npm gates default to **Node/TypeScript** projects. For other stacks, just swap the compile / test commands in `pre-commit-check` / `detect-bug-signal` — the methodology itself is language-agnostic.*

## 来由 · Origin

脱胎于一个长期真实运行的个人 AI 项目，把其中**与具体业务无关的工程方法论**抽象成通用模板。所有个人内容、业务耦合、私有路径均已剥离。

> *Distilled from a long-running, real personal AI project — abstracting its **business-agnostic engineering methodology** into a general template. All personal content, business coupling, and private paths have been stripped out.*

## 姊妹项目 · Related

- **[pinpin.custom-claude-feishu-companion](https://github.com/Dodo-OmO/pinpin.custom-claude-feishu-companion)** —— 我用这套工程系统开发、迭代的飞书 AI 伙伴「品品」（技术作品展示）。
  *Pinpin — a Feishu AI companion I build and iterate on with this very engineering system (a technical showcase).*

## License

[MIT](./LICENSE)
