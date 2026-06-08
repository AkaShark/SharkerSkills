---
name: sdd-tasks
description: SDD 流水线第三阶段——把 design.md 拆解为 specs/<feature>/tasks.md：有序、可独立验证的任务列表，每条带 [依赖]、[涉及模块]、[验收] 标注。涉及模块直接引用 .sdd/knowledge/modules/ 的实体页，为 impl 阶段的逐任务执行与知识沉淀铺好锚点。当用户说「拆任务 / sdd tasks / 把 design 拆成 todo / 出实施计划」且对应 feature 已有 design.md 时使用。
---

# sdd-tasks —— 方案 → 有序任务

把 `design.md` 落成一份可执行的 `tasks.md`：**有序、粒度合适、可独立验证**的任务清单，每条标注**依赖**、**涉及哪些模块**、**怎样算完成**。这是流水线第三棒，承上（design）启下（impl）；任务里对 `knowledge/modules/` 的引用，让 impl 阶段知道该读哪些既有知识、完成后该更新哪些模块页。

> **借鉴透明标注（D2）**：tasks 阶段借鉴 [cc-sdd](https://github.com/gotalab/cc-sdd) 的 `spec→design→tasks→impl` 链（原版 tasks 后接 TDD 实现）；我们裁剪为 skill、存 `.sdd/specs/<feat>/tasks.md`，并在每条任务显式标注 `[涉及模块]` 以挂钩知识库的 `modules/`（本项目紧耦合设计，见 `.sdd/schema.md` §7）。

## 何时使用

- 「拆任务」「sdd tasks」「把 design 拆成可执行的 todo」「出实施计划」
- 对应 feature 的 `design.md` 已就绪，准备进入实现
- 需要把大方案切成能逐个验证、能交给 executor 跑的小步

## 何时不使用

- 对应 feature **还没有 `design.md`**——先用 `sdd-design`
- tasks 已就绪，要开始写代码——用 `sdd-impl`
- 改动是单一原子操作、无需拆解——直接 impl
- 任务管理用的是外部系统（Jira/GitHub Issues）且不想要本地 tasks.md——按需，本 skill 产物是本地 markdown

## 依赖 / 工具

- 对应 feature 的 `.sdd/specs/<feat>/design.md`。
- `.sdd/knowledge/modules/`（用于填 `[涉及模块]`）、`.sdd/constitution.md`（测试/质量红线影响任务粒度）。
- Claude `Read`、`Write`、`Bash`、`Grep` 工具。无外部依赖。

## 工作流程

### Step 1 — 读 design + 盘点涉及模块

```bash
DESIGN=".sdd/specs/<feat>/design.md"
test -f "$DESIGN" || { echo "缺 $DESIGN，先 sdd-design" >&2; exit 1; }
ls .sdd/knowledge/modules/ 2>/dev/null
```

读 `design.md` 的文件结构与关键决策，对照 `knowledge/modules/` 现有实体页，确定每个任务会**碰到哪些模块**（已有页的用 `[[modules/x]]` 引用；将新建的模块标注「(新)」）。

**Acceptance**：已读 design；已列出本 feature 涉及的模块集合（既有 + 新建）。

### Step 2 — 拆任务并排序

写到 `.sdd/specs/<feat>/tasks.md`，规则：

- **有序**：按依赖拓扑排，能先做的排前面。
- **粒度**：每条是一个可独立验证的最小增量（通常 0.5–1 天量级；遵守 constitution 的 TDD 红线时，「写测试」可与「写实现」同条或拆开）。
- **每条三标注**：
  - `[依赖: T1, T3]`（无则 `[依赖: 无]`）
  - `[涉及模块: [[modules/auth-service]], 新建 modules/session-store]`
  - `[验收: <可测条件>]`
- 顶部放一句「实现策略」（是否 TDD、是否分支等，承接 constitution）。

格式建议：

```markdown
# tasks — <feat>

> 实现策略：TDD（先写失败测试）；逐任务交付，每条验收通过再下一条。

- [ ] **T1 <动词短语>**
  - [依赖: 无] · [涉及模块: 新建 modules/session-store] · [验收: 单测覆盖 set/get/expire]
- [ ] **T2 <动词短语>**
  - [依赖: T1] · [涉及模块: [[modules/auth-service]]] · [验收: 登录返回 JWT，e2e 绿]
```

**Acceptance**：每条任务都有依赖 / 涉及模块 / 验收三标注；顺序满足依赖；颗粒度可独立验证。

### Step 3 — 自检依赖闭合

确认：没有任务依赖一个不存在的编号；没有循环依赖；每个 design 里的文件结构改动都被至少一个任务覆盖。

**Acceptance**：依赖编号都存在、无环；design 的改动面被任务完整覆盖（无遗漏）。

### Step 4 — 回执 + 引导

报告 tasks 路径、任务条数、关键依赖链，下一步 `/sharker-sdd:sdd-impl`。**不碰 git。**

**Acceptance**：用户拿到 tasks 路径 + 任务概览 + 下一步命令。

## 输入

- 对应 feature 的 `.sdd/specs/<feat>/design.md`（必需）。
- `.sdd/knowledge/modules/`、`.sdd/constitution.md`。

## 输出

- `.sdd/specs/<feat>/tasks.md`：有序任务，每条带 `[依赖]`/`[涉及模块]`/`[验收]`。
- **不产生业务代码、不动知识库正文（只引用 modules）、不动 git。**

## 反模式

- ❌ 任务无依赖标注、顺序随意——impl 阶段会卡在「这步还缺前置」
- ❌ 验收写成「完成 X 功能」这种不可测描述——验收必须能被一个测试/命令判定
- ❌ 不标 `[涉及模块]`——impl 完成后不知道该更新哪些 `modules/` 页，知识库会漏更新
- ❌ 任务粒度过粗（「实现整个登录」）——无法逐个验证、无法安全交给 executor 并行
- ❌ 漏覆盖 design 里的某些改动——拆任务即承诺实现面，遗漏会让 design 与代码脱节
- ❌ 在 tasks 阶段就写实现代码——这里只产出计划，代码是 impl 的事

## 示例

```
用户：把 user-login 的 design 拆成任务
Claude（本 skill）：
  [Step 1] 读 design.md；modules/ 现有 auth-service，session-store 需新建
  [Step 2] 写 tasks.md：
    T1 建 session-store [依赖:无][涉及:新建 modules/session-store][验收:set/get/expire 单测]
    T2 登录签发 JWT [依赖:T1][涉及:[[modules/auth-service]]][验收:正确凭据返回令牌, e2e 绿]
    T3 refresh 端点 [依赖:T2][涉及:[[modules/auth-service]]][验收:过期令牌可刷新]
  [Step 3] 自检：依赖 T1→T2→T3 无环，覆盖 design 全部改动 ✓
  [Step 4] 回执：3 个任务 → 下一步 /sharker-sdd:sdd-impl
```
