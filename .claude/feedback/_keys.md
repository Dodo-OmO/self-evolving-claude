# 反馈归并键受控词表（recurrence_key controlled vocabulary）

> 作用：feedback-observer 写入前先读本表，给本次反馈选一个**最匹配的现有键**；语义确实是新类才新增一个 `kebab-case` 键并登记到这里。evolution-runner 按归并键聚合计数判毕业。
>
> 用法铁律：**先复用，后新增**——能套现有键就别造新键，否则同一类问题被起不同键 = 计数失真。新增时键名用动宾/主谓的 kebab-case，配一句话定义。

下面是一组**通用起步键**（示范）。按你的项目实际增长，新增登记在表尾并简记"为什么现有键套不上"。

## 已用键

| 归并键 | 一句话定义（什么类型的反馈归这） |
|---|---|
| `subagent-overtrust` | 轻信了子助手的推论/状态判断，没独立核实就采信或转述 |
| `inference-as-fact` | 把"从相邻事实倒推的推断"用肯定语气包装成已验证结论输出，缺直接证据 |
| `verify-evidence-required` | 回报"验证通过/build 通过"没贴具体证据（输出/PASS 数/实测结果） |
| `verify-new-code-loaded` | 改常驻/主进程代码后，验证前没用新版签名确认"跑的就是新代码" |
| `scope-reset-on-repeat-doubt` | 用户对同一设计 ≥2 次质疑后，仍在原方案框架里精修而非回方案层 |
| `absolute-goal-no-discount` | 用户用绝对词（彻底/全部/清零）时，把执行项以"成本高/价值小"降级为不做 |
| `value-claim-without-research` | 带绝对化乐观词（最值得/几乎零/会火/很轻松）的价值或风险判断，没先用实证核实就脱口而出 |
| `token-frugality` | 该省字没省、能引用却复制、常驻提示/工具描述冗余 |
| `reuse-before-new` | 加新代码/函数前没查项目里有没有现成可复用的，重复造轮子 |
| `break-build-sync` | 改动让旧功能/文档失效但没同步清理或落实彻底（破立不同步） |
| `source-driven-api` | 动外部库 API 凭训练印象写，没先查官方文档对版本 |
| `task-md-realtime` | 任务记录没实时回写/写错路径/没按模板，外置大脑失效 |
| `ask-upfront-batch` | 开工前没把模糊点一次问清，做到一半才回来问本可一次问清的事 |
| `cleanup-process-artifacts` | 任务结束没回扫删除本会话产生的过程产物（临时脚本/fixture/备份） |
| `windows-crlf-script` | 用 Edit/Write 改 .bat/.cmd 导致 LF 行尾，Windows 脚本静默失效 |
| `devil-advocate-proactive-gate` | 方案明显收敛后，没主动识别"v1 定型节点"并主动派 devil-advocate，等用户提醒才触发 |
| `devil-advocate-critical-skip` | devil-advocate 给出 Critical 警告，主对话"自以为想通了"略过未充分消化 |
| `capability-boundary-no-dead-conclusion` | 平台新特性/能力边界文档有张力或留白时，凭字面下"能/不能"确定结论，不标注不确定+实测 |

## 新增登记区

> 新键加在上表，并在此简记一句"为什么现有键套不上"，便于回溯键是否该合并。

（按你的项目积累）
