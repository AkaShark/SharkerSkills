---
name: sdd-design
description: SDD 流水线第二阶段——把 spec.md 推导为 specs/<feature>/design.md（架构概述 + 关键决策含「为什么/备选/取舍」 + 文件结构 + 可选 Mermaid 图）。结尾把本次有取舍的架构决策沉淀进 .sdd/knowledge/decisions/ 并回写 index.md，形成知识复利。当用户说「写 design / sdd design / 出技术方案 / 设计架构」且对应 feature 已有 spec.md 时使用。
---

# sdd-design —— 规格 → 技术方案

把 `spec.md` 的「做什么」推导成「怎么做」：一份结构化 `design.md`，讲清架构、**每个关键决策的取舍**、文件结构、必要时配 Mermaid 图。这是流水线第二棒，也是横向知识复利的**沉淀触发点**——**收尾时把有取舍的架构决策写进知识库**，让下个 feature 自动受益。

> **借鉴透明标注（D2）**：design 阶段（带 Mermaid）借鉴 [cc-sdd](https://github.com/gotalab/cc-sdd)（原版 design.md 带 Mermaid 图）；Mermaid 本 skill **推荐不强制**。结尾沉淀 `decisions/` 是本项目紧耦合闭环的关键环节（见 `.sdd/schema.md` §7），ADR 思路通用，知识库互联 wiki 模型借鉴 [karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)。

## 何时使用

- 「写 design」「sdd design」「出技术方案」「设计这个 feature 的架构」
- 对应 feature 的 `spec.md` 已就绪，要进入「怎么做」
- 需要把多个备选方案的取舍记录下来

## 何时不使用

- 对应 feature **还没有 `spec.md`**——先用 `sdd-spec`
- design 已就绪，要拆任务——用 `sdd-tasks`
- 改动极小、无架构决策可言——直接进 impl，别为形式写 design
- 用户想直接写代码、跳过设计——尊重选择，但提示这会断掉决策沉淀

## 依赖 / 工具

- 对应 feature 的 `.sdd/specs/<feat>/spec.md`。
- `.sdd/knowledge/`（读 + 写 decisions）、`.sdd/constitution.md`、`.sdd/schema.md`。
- Claude `Read`、`Write`、`Bash`、`Grep` 工具。无外部依赖。

## 工作流程

### Step 1 — 读 spec + 复核约束 + 召回相关决策

```bash
SPEC=".sdd/specs/<feat>/spec.md"
test -f "$SPEC" || { echo "缺 $SPEC，先 sdd-spec" >&2; exit 1; }
```

读 `spec.md`、`constitution.md`（技术栈红线/架构边界）、并按 schema §4 召回 `knowledge/decisions/` 与 `modules/` 里相关页（grep 关键词），避免与既有决策冲突或重复发明。

**Acceptance**：已读 spec + constitution；已召回相关历史决策（或确认无）。

### Step 2 — 起草 design.md

写到 `.sdd/specs/<feat>/design.md`，含：

1. **架构概述**：整体怎么搭，数据/控制流（可选 Mermaid `flowchart` / `sequenceDiagram`）。
2. **关键决策**：逐条，每条配 **「决策 / 备选 / 取舍理由」** 三件套——这是后续沉淀进 `decisions/` 的原料。
3. **文件结构**：要新增/改动哪些文件、目录，涉及哪些既有 `modules/`。
4. **风险 / 未决点**：已知风险、待验证假设。

**Acceptance**：`design.md` 四块齐全；关键决策每条都有「备选 + 取舍」，不是单选项陈述。

### Step 3 — 沉淀决策进知识库（紧耦合·结尾必做）

按 `.sdd/schema.md` §3 把 Step 2 里**有取舍**的决策 ingest 进 `knowledge/decisions/`：

- 每个独立决策一页：`knowledge/decisions/<verb-phrase>.md`，front-matter 带 `type: decision`、`source: specs/<feat>` / commit、`tags`。
- 正文：背景 / 被否决的备选 / 最终选择 + 理由；用 `[[modules/...]]`、`[[lessons/...]]` 互链。
- **优先织进既有页**：若已有相关 decision，改写补充而非新建重复页（karpathy 的「记账」原则）。
- **回写 `knowledge/index.md`**：在 decisions 分区加/更新一行摘要 + 更新底部统计。

**Acceptance**：本次每个有取舍的决策都落了一页（或更新了既有页）；`index.md` 已同步；新页带合规 front-matter 与 `source`。

### Step 4 — 回执 + 引导

报告 design 路径、沉淀了哪几条决策、下一步 `/sharker-sdd:sdd-tasks`。**不碰 git。**

**Acceptance**：用户拿到 design 路径 + 已沉淀决策清单 + 下一步命令。

## 输入

- 对应 feature 的 `.sdd/specs/<feat>/spec.md`（必需）。
- `.sdd/constitution.md`、`.sdd/knowledge/`。

## 输出

- `.sdd/specs/<feat>/design.md`（架构 / 关键决策 / 文件结构 / 风险）。
- **新增/更新** `.sdd/knowledge/decisions/*.md` + 同步后的 `index.md`。
- **不产生业务代码、不动 git。**

## 反模式

- ❌ 「关键决策」只写选了什么、不写备选和理由——没有取舍记录的决策，沉淀进知识库也没价值
- ❌ 跳过 Step 3 沉淀——design 写完决策就蒸发，闭环断裂，下个 feature 还会重新纠结同样的取舍
- ❌ 沉淀时每条都新建文件、不复用既有 decision 页——制造重复与矛盾，违背 schema 的「织进现有页」
- ❌ 忘了回写 `index.md`——沉淀了却召回不到，等于白沉淀（孤儿页）
- ❌ 把实现细节（具体函数代码）塞进 design——design 讲方案与取舍，代码留给 impl
- ❌ 决策与 `constitution.md` 的技术栈红线冲突却不标注——要么遵守，要么显式说明为何破例

## 示例

```
用户：给 user-login 写 design
Claude（本 skill）：
  [Step 1] 读 spec.md + constitution（红线：仅 TS strict）
           召回 decisions/ 无相关，modules/ 命中 [[modules/auth-service]]
  [Step 2] 写 design.md：
           · 决策：会话用 JWT 还是 server session？
             备选：server session（易吊销，但需共享存储）
             选择：JWT 短期 + refresh，取舍=无状态扩展优先，吊销用黑名单兜底
           · Mermaid sequenceDiagram 画登录流
  [Step 3] 沉淀 → knowledge/decisions/use-jwt-over-session.md
           回写 index.md（decisions 1 → 注明 source: specs/user-login）
  [Step 4] 回执：design 就绪，沉淀 1 条决策 → 下一步 /sharker-sdd:sdd-tasks
```
