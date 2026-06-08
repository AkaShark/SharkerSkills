---
name: sdd-impl
description: SDD 流水线第四阶段——按 tasks.md 逐任务实现（编排 OMC executor 执行 + TDD + 逐任务 code-reviewer/verifier 复核，不重造执行 agent）。过程中 debug 成功定位非显然坑就沉淀进 .sdd/knowledge/lessons/，任务完成后更新 .sdd/knowledge/modules/，并回写 index.md，形成知识复利闭环。当用户说「开始实现 / sdd impl / 按 tasks 干 / 跑实施」且对应 feature 已有 tasks.md 时使用。
---

# sdd-impl —— 任务 → 可工作的代码

按 `tasks.md` 一条条把任务变成**通过验收的代码**。本 skill 是**流程编排层**，不自己写执行引擎——它把每个任务交给 OMC 的 `executor`（复杂任务 `model=opus`）实现，交给 `code-reviewer`/`verifier` 复核，自己负责**顺序、验收闸门、以及两处知识沉淀**：debug 成功 → `lessons/`，任务完成 → `modules/`。这是纵向流水线的终点，也是横向知识复利最密集的沉淀点。

> **借鉴透明标注（D2）**：impl 阶段（TDD + 自动 debug）借鉴 [cc-sdd](https://github.com/gotalab/cc-sdd)（原版 impl 自带 TDD + debug 循环）；我们**不自带执行 agent**，改为复用 OMC 的 `executor` / `code-reviewer` / `verifier`（SDD skill 只做编排）。「learnings/errors 自动沉淀」借鉴 [AddyOsmani self-improving agents](https://addyosmani.com/blog/self-improving-agents/)，并入 `knowledge/lessons/`、由本阶段触发（见 `.sdd/schema.md` §3、§7）。

## 何时使用

- 「开始实现」「sdd impl」「按 tasks 把它做出来」「跑实施」
- 对应 feature 的 `tasks.md` 已就绪，进入写代码阶段
- 想要逐任务执行 + 复核 + 自动沉淀知识的受控实现流程

## 何时不使用

- 对应 feature **还没有 `tasks.md`**——先用 `sdd-tasks`
- 一行修改 / 紧急 hotfix——直接改 + 自测，别套整套编排
- 用户明确要自己手写、不要 agent 编排——尊重，但提示这会跳过自动沉淀（可事后 `kb-save` 兜底）
- 任务本质是探索性 spike 而非交付——先 spike，结论回流到 design/knowledge 再 impl

## 依赖 / 工具

- 对应 feature 的 `.sdd/specs/<feat>/tasks.md`、`design.md`、`spec.md`。
- `.sdd/knowledge/`（读召回 + 写 lessons/modules）、`.sdd/constitution.md`、`.sdd/schema.md`。
- **OMC agents**：`executor`（实现，复杂用 `model=opus`）、`code-reviewer` / `verifier`（复核）。本 skill 通过 `Agent` 工具委派，不重造。
- Claude `Read`、`Write`、`Edit`、`Bash`、`Agent`、`Grep` 工具。

## 工作流程

> **总纲**：逐任务循环 `召回 → 执行 → 复核 → 沉淀`。**作者与复核分离**——执行交 `executor`，复核必须由独立的 `code-reviewer`/`verifier` 做，不在同一上下文自我批准（对齐 OMC 纪律）。

### Step 1 — 载入上下文 + 召回相关知识

```bash
T=".sdd/specs/<feat>/tasks.md"
test -f "$T" || { echo "缺 $T，先 sdd-tasks" >&2; exit 1; }
```

读 tasks/design/spec/constitution；按 schema §4 召回与本 feature 相关的 `lessons/`、`patterns/`、`modules/`（grep 关键词）——**带着历史教训开工**，别重踩。

**Acceptance**：已读四件套；已召回相关 lessons/patterns/modules（或确认无）。

### Step 2 — 逐任务执行（委派 executor）

按 `tasks.md` 顺序，对每个未完成任务 `Tn`：

1. 取该任务的 `[涉及模块]`，把对应 `modules/` 页 + 命中的 `lessons/` 作为上下文。
2. 委派 `executor`（复杂任务 `model=opus`）实现该任务，遵守 constitution（如 TDD：先写失败测试）。
3. **遇到 bug 时**：定位 → 修复。**若根因非显然**（不是 typo/一眼可见），记下「现象/根因/正确做法」，留待 Step 4 沉淀 `lessons/`。

**Acceptance**：当前任务的代码 + 测试就绪，本地自测通过该任务 `[验收]`；非显然 debug 已记下待沉淀。

### Step 3 — 逐任务复核（委派 code-reviewer / verifier，独立上下文）

把该任务的改动交给 `code-reviewer`（或 `verifier`）复核：是否满足 `[验收]`、是否违反 constitution、有无回归。**不通过就回 Step 2 迭代**，通过才勾选 `tasks.md` 里的 `- [ ]` → `- [x]`，进入下一任务。

**Acceptance**：复核通过且 `[验收]` 满足；`tasks.md` 勾选已更新；复核由独立 agent 完成（非自我批准）。

### Step 4 — 沉淀知识（紧耦合·贯穿全程）

按 `.sdd/schema.md` §3 触发条件落知识：

- **debug 成功定位非显然坑** → 写 `knowledge/lessons/<phrase>.md`（现象/根因/复现/正确做法；front-matter `type: lesson`、`source: <commit或specs/<feat>>`、`tags`；用 `[[modules/...]]` 互链）。
- **任务/feature 完成、模块「干什么/为什么」有更新** → 新建或改写 `knowledge/modules/<module>.md`。
- **发现可复用模式** → 写 `knowledge/patterns/`。
- 每次写页**都回写 `knowledge/index.md`** 摘要 + 统计（漏写 = 孤儿页）。
- 优先**织进既有页**而非堆新文件（karpathy「记账」原则）。

**Acceptance**：本次所有满足触发条件的知识都已落页并回写 index；新页 front-matter 合规、含 `source`、有互链。

### Step 5 — 收尾回执

报告：完成了哪些任务、沉淀了哪几页 lessons/modules/patterns、`tasks.md` 勾选进度、剩余任务。提示可 `/sharker-sdd:kb-lint` 巡检知识库。**不碰 git**（commit 由用户做）。

**Acceptance**：用户拿到任务完成进度 + 沉淀清单 + 剩余任务；未执行 git。

## 输入

- 对应 feature 的 `.sdd/specs/<feat>/{tasks,design,spec}.md`（必需 tasks.md）。
- `.sdd/knowledge/`、`.sdd/constitution.md`、`.sdd/schema.md`。

## 输出

- **业务代码 + 测试**（由 executor 产出，落在项目源码树）。
- 更新后的 `tasks.md`（勾选进度）。
- **新增/更新** `.sdd/knowledge/lessons/`、`modules/`、`patterns/` + 同步的 `index.md`。
- **不动 git**——提交交还用户。

## 反模式

- ❌ 自己上手写执行引擎/不用 executor——本 skill 是编排层，重造执行 agent 违背设计（见 schema §7 与 blueprint §3.3）
- ❌ 执行与复核在同一上下文自我批准——必须 `code-reviewer`/`verifier` 独立复核（OMC 纪律）
- ❌ debug 完坑就忘——非显然根因不沉淀 `lessons/`，下个 feature 还会重踩，闭环断裂
- ❌ 把一次性琐碎 debug 也写成 lesson——宁缺毋滥，只记非显然的（schema §3「不要 ingest」清单）
- ❌ 任务全做完才想起更新 `modules/`——完成一个就更新，避免堆积后漏写
- ❌ 沉淀了 lesson/module 却忘回写 `index.md`——召回不到 = 白沉淀
- ❌ 跳过 Step 1 召回直接干——历史教训不进上下文，等于关掉复利
- ❌ 顺手 `git commit`/`push`——本 skill 不碰 git

## 示例

```
用户：开始实现 user-login
Claude（本 skill）：
  [Step 1] 读 tasks/design/spec/constitution；召回 lessons/oauth-token-refresh-race ⇒ 进上下文
  [Step 2] T1 session-store → executor(model=opus) 写实现+单测
           debug：fork 后 sqlite "database is locked"——根因非显然（连接跨进程复用）
  [Step 3] code-reviewer 复核 T1：验收 set/get/expire 单测绿 ✓ → tasks.md 勾选 T1
  [Step 4] 沉淀 lessons/sqlite-locked-on-fork.md（根因+正确做法：每进程独立连接）
           回写 index.md（lessons 1）；T1 完成 → 更新 modules/session-store.md
  ... T2 / T3 同循环 ...
  [Step 5] 回执：3/3 任务完成，沉淀 1 lesson + 2 modules；建议 /sharker-sdd:kb-lint。未提交。
```
