---
type: schema
status: protocol
created: {{DATE}}
updated: {{DATE}}
---

# 知识库行为协议 (schema.md)

> **这是给 AI 看的行为契约**，不是给人读的文档。它定义了 `.sdd/knowledge/` 这个工程知识库**怎么结构化、何时写入、怎么召回、怎么防腐**。
> 任何在本项目里工作的 AI 助手，在涉及知识库的读写时都必须遵守本文件。
>
> 借鉴自 [karpathy 的 LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)（raw / wiki / schema 三层 + ingest / query / lint 三操作；<100k token 时 AI 维护的互联 markdown wiki 胜过 RAG）。我们的改法：知识源从「用户喂的外部文档」换成**开发过程本身**（debug / 决策 / 模式）；实体页分四类工程类型；schema 从项目根 `CLAUDE.md` 独立成 `.sdd/schema.md`（避免污染项目主 CLAUDE.md）；触发机制为 **AI 自主 + `/kb-save` 手动兜底**。

---

## 1. 三层心智模型

| 层 | 文件 | 谁拥有 | 变更频率 |
|---|---|---|---|
| **法律（稳定）** | `constitution.md` | 人 | 极低 |
| **判例 + 笔记（演进）** | `knowledge/**` | **AI 完全拥有** | 随开发持续生长 |
| **行为协议** | `schema.md`（本文件） | 人定框架、AI 遵守 | 低 |

`knowledge/` 是 AI 完全拥有的结构化 markdown 区域：你可以自由创建、改写、合并、删除其中的页面，目标是让它始终是**当前最准确、最互联、最少冗余**的工程知识快照。

## 2. 四类实体页（写到哪个目录）

| 目录 | 装什么 | 典型触发 |
|---|---|---|
| `knowledge/modules/` | **模块/组件实体页**：这块代码干什么、关键文件、为什么这样设计、对外接口、已知约束 | 做完一个 feature / 重构一个模块后 |
| `knowledge/decisions/` | **架构决策记录 (ADR)**：一个有取舍的决策 + 备选方案 + 选择理由 | 定完一个技术方案后（`sdd-design` 结尾自动触发） |
| `knowledge/lessons/` | **踩坑教训**：一个**非显然**的 bug 根因 + 复现条件 + 正确做法 | debug 成功定位一个不直观的坑后（`sdd-impl` 触发） |
| `knowledge/patterns/` | **代码模式/约定**：一个会在项目里复用的写法、命名约定、目录约定 | 发现/确立一个可复用模式后 |

> 不确定归哪类时的优先级：**lessons（最具体、最值钱）> decisions > patterns > modules**。一条知识若同时是「坑」和「决策」，优先记为 lesson 并在 decision 里 `[[链接]]` 它，不要两处复制正文。

## 3. Ingest —— 何时写入（AI 自主行为协议）

**当且仅当**满足下列任一条件，你应当**主动**把它 ingest 进知识库（无需用户开口）：

- **(a)** 你 debug 成功，定位到一个**非显然**的根因（不是 typo、不是一眼可见的错误）→ 写 `lessons/`
- **(b)** 你做出一个**有取舍**的架构/技术决策（存在被否决的备选）→ 写 `decisions/`
- **(c)** 你发现或确立一个**会被复用**的模式/约定 → 写 `patterns/`
- **(d)** 你完成或显著改动一个模块，其「干什么/为什么」值得后人快速了解 → 新建/更新 `modules/`

**不要** ingest 的东西：一次性的琐碎操作、显而易见的常识、能从代码/git 直接读出的事实、还没验证成立的猜测。**宁缺毋滥**——知识库的价值在信噪比。

> Ingest ≠ 追加一个新文件了事。karpathy 的核心论点是：LLM 最擅长人类最烦的「记账」——把新知识**织进**现有页、更新交叉引用。所以 ingest 时**先查有没有相关页**：有就改写/补充既有页，没有才新建。

### 3.1 写入纪律（每页必须遵守）

每个知识页是一个 markdown 文件，文件名 kebab-case（如 `oauth-token-refresh-race.md`），**必须**带 front-matter：

```markdown
---
type: lesson            # module | decision | lesson | pattern
created: {{DATE}}
updated: {{DATE}}
source: <commit hash 或 specs/<feat>/ 或 "manual:/kb-save">
tags: [auth, async, race-condition]
---

# <标题：一句话说清这页讲什么>

## 现象 / 背景
...

## 根因 / 决策 / 模式
...

## 正确做法 / 取舍
...

## 关联
- 相关模块：[[modules/auth-service]]
- 相关决策：[[decisions/use-jwt-over-session]]
```

- **互链**：用 `[[目录/页名]]`（不含 `.md`）引用其它页，像 wiki 一样织网。
- **写完必做**：回到 `knowledge/index.md`，在对应分区加/更新该页的**一行摘要**，并更新底部统计计数。**index 永远是 knowledge/ 的真实索引**——漏更新 index 的页 = 召回不到的孤儿页。
- **改写既有页**：同步更新它的 `updated` 字段。

## 4. Query —— 怎么召回（不上 RAG/embedding）

召回流程（`kb-query` skill 和 `sdd-spec` 开头都走这套）：

1. **读 `knowledge/index.md`**（这是唯一入口，永远先读它）。
2. 按问题里的关键词 / tags，在 index 的摘要里判断**哪几页相关**；必要时 `grep -ri "<关键词>" knowledge/` 补充定位。
3. **只读命中的那几页**全文（不是全部页）。
4. 综合回答，并**标注来源页**（如「依据 `lessons/oauth-token-refresh-race`」）。

> 为什么不上 embedding：在规模红线内（见 §6），结构化互联 markdown 的检索是 **100% 可靠**的（index + grep 精确命中），无 chunking 损失、零检索基建。这是 karpathy 论点在工程场景的应用。

## 5. Lint —— 防腐（`kb-lint` skill）

定期巡检知识库健康度，检查：

1. **矛盾**：两页对同一事实的说法冲突。
2. **过时**：对照当前代码，某条 lesson/module 是否还成立（接口已改、坑已被框架修复等）。
3. **孤儿页**：存在于 `knowledge/` 但没被 `index.md` 收录、也没被任何 `[[链接]]` 引用的页。
4. **缺失交叉引用**：明显相关的两页之间没有 `[[链接]]`。
5. **规模红线**：见 §6。

Lint **产出报告 + 修复建议**，由人确认；**不自动删除**知识页。

## 6. 召回规模红线（硬约束）

> `index.md` + 单次召回读入的页面总量，控制在 **~50k token 以内**。

一旦 `knowledge/` 增长到威胁这条线（`kb-lint` 会告警），再考虑：拆分领域子 index、或引入检索。**但在触线之前，不要引入任何检索基建**——结构化 markdown 全量进 context 在这个规模内就是最优解。这条红线是本知识库「先不上 RAG」决策的量化护栏。

## 7. 与 SDD 流水线的挂钩（紧耦合）

知识库不是被动仓库，而是嵌入开发流程的复利闭环：

- `sdd-spec` **开头** → 召回（读 index 找历史相关坑/决策）
- `sdd-design` **结尾** → 沉淀 `decisions/`
- `sdd-impl` **debug 成功** → 沉淀 `lessons/`；**完成** → 更新 `modules/`
- 任何时刻用户说「记一下」→ `kb-save` 兜底

这套挂钩写在各 SDD skill 的工作流 Step 里（流程即协议）。本 schema 是那些 Step 的「为什么这么做」的权威定义。
