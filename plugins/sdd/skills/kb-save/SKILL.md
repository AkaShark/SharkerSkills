---
name: kb-save
description: 工程知识库手动沉淀兜底——当用户说「把这个记下来 / 存进知识库 / kb save / 记一下这个坑/决策/模式」时，把当前上下文里的一段知识结构化成一个知识页，按四类（modules/decisions/lessons/patterns）写入 .sdd/knowledge/ 对应目录，带合规 front-matter 与 [[互链]]，并回写 index.md。这是 AI 自主沉淀之外的显式入口。当 AI 没有自动沉淀、或用户想主动归档某条经验时使用。
---

# kb-save —— 手动沉淀兜底

把当前对话里的一段值得留存的知识，**结构化成一个知识页**写进 `.sdd/knowledge/`。SDD 各阶段会自动沉淀（schema 行为协议），但总有「AI 没自动记 / 用户临时想归档某条经验」的情况——本 skill 就是那个**显式兜底入口**。它负责选对目录、套对模板、写合规 front-matter、回写 index，让手动沉淀和自动沉淀产出**完全同构**的页。

> **借鉴透明标注（D2）**：知识库 = AI 维护的互联 wiki，借鉴 [karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)（原版 ingest 由人工/事件触发，把新信息织进现有页）。我们把「手动沉淀」做成 `kb-save`，作为 AI 自主沉淀（`schema.md` 行为协议）之外的兜底（见 blueprint「KB 写入：AI 自主为主 + `/kb-save` 兜底」）。

## 何时使用

- 「把这个记下来」「存进知识库」「kb save」「记一下这个坑/决策/模式」
- 刚解决一个问题 / 拍了一个决策，想主动归档，而 AI 没自动沉淀
- 复盘时把一条口头经验固化成知识页

## 何时不使用

- 项目里**没有 `.sdd/`**——先 `sdd-init`
- 这条「知识」其实能从代码/git 直接读出、或是一次性琐事——schema §3「不要 ingest」清单，别污染知识库
- 正在跑 `sdd-design`/`sdd-impl`，沉淀本就是其内建 Step——交给它们自动做，不必手动
- 用户想**召回**已有知识——那是 `kb-query`
- 用户想**体检**知识库——那是 `kb-lint`

## 依赖 / 工具

- 已存在的 `.sdd/knowledge/` 与 `.sdd/schema.md`（模板与纪律的权威来源）。
- Claude `Read`、`Write`、`Edit`、`Bash`、`Grep` 工具。无外部依赖。

## 工作流程

### Step 1 — 判类型 + 查重

```bash
test -d .sdd/knowledge || { echo "未找到 .sdd/knowledge，先 sdd-init" >&2; exit 1; }
```

- 按 `.sdd/schema.md` §2 判断这条知识属哪类：`lesson`（非显然坑）/ `decision`（有取舍决策）/ `pattern`（可复用模式）/ `module`（模块实体）。不确定时按优先级 **lesson > decision > pattern > module**。
- **查重**：`grep -ri "<关键词>" .sdd/knowledge/` 看是否已有相关页——**有就改写补充既有页**，没有才新建（karpathy「织进现有页」）。

**Acceptance**：已定类型与目标目录；已确认是「新建」还是「更新既有页」。

### Step 2 — 结构化成知识页

按 schema §3.1 模板写到 `.sdd/knowledge/<type-dir>/<kebab-title>.md`：

```markdown
---
type: lesson
created: <today>
updated: <today>
source: manual:/kb-save        # 手动沉淀显式标注来源
tags: [<领域关键词>]
---

# <一句话标题>

## 现象 / 背景
## 根因 / 决策 / 模式
## 正确做法 / 取舍
## 关联
- [[modules/...]] / [[decisions/...]]
```

- 标题与正文**由 AI 提炼**，不照搬用户原话流水账。
- `source` 标 `manual:/kb-save`（与自动沉淀的 commit/spec 来源区分）。
- 加 `[[互链]]` 把它织进知识网。

**Acceptance**：页面 front-matter 合规（type/created/updated/source/tags 齐全）；正文四块结构化；至少尝试了相关 `[[互链]]`。

### Step 3 — 回写 index.md（必做）

在 `.sdd/knowledge/index.md` 对应分区加/更新一行摘要，并更新底部统计计数与 `末次更新` 日期。

**Acceptance**：`index.md` 能查到这页（新增/更新的一行摘要 + 统计已同步）。

### Step 4 — 回执

报告写到哪个文件、归为哪类、回写了 index。**不碰 git。**

**Acceptance**：用户拿到页面路径 + 类型 + index 已更新确认。

## 输入

- **要沉淀的知识**（来自当前对话上下文，或用户显式粘贴的一段）。
- 可选：用户指定的类型/标题/tags（不指定则 AI 判定）。
- 已存在的 `.sdd/knowledge/`。

## 输出

- 一个新增或更新的 `.sdd/knowledge/<type>/<title>.md`（front-matter + 四块正文 + 互链）。
- 同步后的 `.sdd/knowledge/index.md`。
- **不动业务代码、不动 git。**

## 反模式

- ❌ 把用户原话整段粘进去当正文——必须结构化（现象/根因/正确做法），否则召回时没法用
- ❌ 每次都新建文件、不查重——制造重复页与矛盾，违背 schema「织进现有页」
- ❌ 忘回写 `index.md`——手动沉淀的页同样会变孤儿页，召回不到
- ❌ 把一次性琐事/常识也存进来——schema §3 明确「宁缺毋滥」，信噪比是知识库的命
- ❌ 类型乱归（把决策塞进 lessons）——按 schema §2 判，归错会让召回路径失效
- ❌ 漏标 `source: manual:/kb-save`——来源可追溯性是写入纪律的一部分
- ❌ 顺手 `git commit`——本 skill 不碰 git

## 示例

```
用户：刚那个 CORS 预检的坑，记到知识库里
Claude（本 skill）：
  [Step 1] 判类型=lesson；grep "cors/preflight" 无既有页 → 新建
  [Step 2] 写 .sdd/knowledge/lessons/cors-preflight-credentials.md
           现象：带 cookie 跨域 401；根因：预检要求 ACAO 不能为 *；
           正确做法：回显具体 Origin + ACA-Credentials:true；source: manual:/kb-save
           关联：[[modules/api-gateway]]
  [Step 3] 回写 index.md（lessons +1）
  [Step 4] 回执：已存 lessons/cors-preflight-credentials，index 已更新。未提交。
```
