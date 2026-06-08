---
name: kb-query
description: 工程知识库召回——读 .sdd/knowledge/index.md 找相关页，按 tags/关键词定位，只读命中的那几页全文，综合回答并标注来源页。纯 grep + 按需读，不做 embedding/RAG（规模红线内结构化 markdown 检索 100% 可靠）。也被 sdd-spec 开头自动调用。当用户说「查知识库 / kb query / 这个之前怎么处理的 / 有没有相关的坑/决策 / 召回历史经验」时使用。
---

# kb-query —— 知识库召回

回答「这个问题，项目历史上有没有相关的坑、决策、模式或模块说明」。流程极简：**读 index → 定位相关页 → 只读那几页 → 综合并标注来源**。不建索引、不做 embedding——在规模红线（~50k token）内，结构化互联 markdown 的精确检索就是最优解。`sdd-spec` 开头也复用这套召回。

> **借鉴透明标注（D2）**：召回模型借鉴 [karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 的 Query（<100k token 时 AI 维护的互联 markdown 胜过 RAG：100% 检索可靠、无 chunking 损失、零基建）。我们的改法：召回入口是 `index.md`，定位用 `grep`，**明确先不上 embedding**（见 `.sdd/schema.md` §4、§6）。

## 何时使用

- 「查一下知识库」「kb query」「这个之前是怎么处理的」
- 「有没有相关的坑 / 决策 / 模式」「召回一下历史经验」
- 动手前想确认「这块以前踩过什么」（也可直接走 `sdd-spec`，它内建召回）
- 想快速了解某个模块「干什么、为什么这么设计」

## 何时不使用

- 项目里**没有 `.sdd/knowledge/`**——先 `sdd-init`
- 用户想**写入**知识——那是 `kb-save`（或让 SDD 阶段自动沉淀）
- 用户想**体检**知识库矛盾/过时/孤儿——那是 `kb-lint`
- 答案显然能从当前代码/文档直接读出、与历史经验无关——直接读代码更快

## 依赖 / 工具

- 已存在的 `.sdd/knowledge/index.md` 及各类知识页。
- Claude `Read`、`Grep`、`Bash` 工具。无外部依赖、无 embedding。

## 工作流程

### Step 1 — 读 index（唯一入口）

```bash
test -f .sdd/knowledge/index.md || { echo "未找到 .sdd/knowledge/index.md，先 sdd-init" >&2; exit 1; }
```

读 `.sdd/knowledge/index.md` 全文——这是召回的唯一入口，永远先读它（它本身在规模红线内）。

**Acceptance**：已读 index.md，掌握四类分区的页清单与一句话摘要。

### Step 2 — 定位相关页

- 从用户问题提取关键词 / 领域 tags，在 index 摘要里判断哪几页相关。
- 摘要不足以判定时，`grep -ri "<关键词>" .sdd/knowledge/`（含 front-matter 的 `tags`）补充定位。
- 把候选收敛到**真正相关的少数几页**（守住 §6 规模红线，不要无脑全读）。

**Acceptance**：得到一份命中页清单（可能为空）；总量在规模红线内。

### Step 3 — 只读命中页 + 综合

- **只读命中的那几页**全文（不是整个 knowledge/）。
- 顺着页内 `[[互链]]` 按需追读强相关的 1–2 跳。
- 综合成回答，**逐条标注来源页**（如「依据 `lessons/sqlite-locked-on-fork`」）。

**Acceptance**：回答有据可查，每个结论标注了来源页；未超规模红线。

### Step 4 — 回执（含空命中处理）

- 有命中：给结论 + 来源页 + （如相关）可行动建议。
- **零命中**：明确说「知识库暂无相关记录」——这本身是有用信号（提示这是新领域，做完记得沉淀）。**不要编造**。

**Acceptance**：用户得到带来源的答案，或一个诚实的「无记录」结论。

## 输入

- **用户的问题 / 关键词 / 主题**（必需）。
- 已存在的 `.sdd/knowledge/`。

## 输出

- 一段**带来源页标注**的综合回答（纯读取，不改任何文件）。
- 零命中时：诚实的「无相关记录」+ 建议（做完此事后沉淀）。
- **不写入知识库、不动 git。**

## 反模式

- ❌ 跳过 index 直接 grep 全库——index 是为「先看目录再翻页」设计的，跳过它既慢又易漏摘要级线索
- ❌ 把整个 `knowledge/` 全读进来——违背规模红线与「只读命中页」的召回纪律
- ❌ 给结论不标来源页——召回的价值一半在「可追溯」，无出处的结论无法被信任/复核
- ❌ 零命中时编一个看似合理的答案——必须诚实报「无记录」，否则比没有知识库更危险
- ❌ 顺手「优化」知识页内容——query 是**只读**操作，改写是 kb-save/kb-lint 的事
- ❌ 为了「更准」而引入 embedding/向量库——红线内明确不上，触线由 kb-lint 告警后再议

## 示例

```
用户：我们处理 fork 之后数据库连接有什么讲究吗？
Claude（本 skill）：
  [Step 1] 读 index.md
  [Step 2] grep "fork/sqlite/connection" → 命中 lessons/sqlite-locked-on-fork
  [Step 3] 读该页 → 综合
  [Step 4] 回执：
    有。依据 `lessons/sqlite-locked-on-fork`：跨进程复用同一 sqlite 连接会触发
    "database is locked"。正确做法：每个进程 fork 后重建独立连接，别继承父进程句柄。
    关联模块 [[modules/session-store]]。
```

**零命中示例**

```
用户：我们用过 GraphQL 订阅吗？
Claude（本 skill）：
  [Step 1-2] 读 index + grep "graphql/subscription" → 无命中
  [Step 4] 回执：知识库暂无 GraphQL 订阅相关记录（属新领域）。
           建议做完后用 /sharker-sdd:kb-save 或在 sdd-impl 阶段沉淀经验。
```
