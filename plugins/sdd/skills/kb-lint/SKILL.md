---
name: kb-lint
description: 工程知识库防腐巡检——检查 .sdd/knowledge/ 的①矛盾(两页说法冲突)②过时(对照当前代码验证 lesson/module 是否还成立)③孤儿页(没被 index 或任何 [[链接]] 引用)④缺失交叉引用⑤召回规模红线(index+常读页是否逼近 ~50k token)。产出报告 + 修复建议，不自动删。当用户说「巡检知识库 / kb lint / 体检知识库 / 查矛盾过时孤儿页 / 知识库健康度」时使用。
---

# kb-lint —— 知识库防腐巡检

知识库会随开发膨胀、随代码演进而过时。本 skill 给 `.sdd/knowledge/` 做一次体检：找**矛盾、过时、孤儿页、缺失交叉引用**，并盯住**召回规模红线**。它只**产出报告 + 修复建议**交人确认，**绝不自动删除**知识页——删错一页历史经验的代价远大于留一页待核。

> **借鉴透明标注（D2）**：Lint 操作借鉴 [karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 的三操作之一（查矛盾/过时/孤儿页）。我们的改法：增加「对照**当前代码**验证 lesson/module 是否还成立」（工程场景特有），并把「召回规模红线 ~50k token」作为显式检查项（见 `.sdd/schema.md` §5、§6）。

## 何时使用

- 「巡检知识库」「kb lint」「给知识库做个体检」
- 「查一下有没有矛盾 / 过时 / 孤儿页」「知识库健康度怎样」
- 知识库积累到一定规模、担心它开始腐烂或逼近召回红线
- 重构/大改后，想确认哪些 lesson/module 页可能已失效

## 何时不使用

- 项目里**没有 `.sdd/knowledge/`**——先 `sdd-init`
- 知识库才刚建、页数寥寥——没什么可 lint，跳过
- 用户想**写入**或**召回**——那是 `kb-save` / `kb-query`
- 用户想让它**自动删页**——本 skill 设计上拒绝自动删，只给建议

## 依赖 / 工具

- `.sdd/knowledge/`（index + 各页）、当前项目源码（用于「过时」核验）。
- Claude `Read`、`Grep`、`Bash` 工具；token 估算用字符数粗算（约 `chars/4`）。无外部依赖。

## 工作流程

### Step 1 — 盘点 + 一致性核对（孤儿 / index 同步）

```bash
test -d .sdd/knowledge || { echo "未找到 .sdd/knowledge，先 sdd-init" >&2; exit 1; }
# 列出所有知识页（排除 index 与目录 README）
find .sdd/knowledge -name '*.md' ! -name 'index.md' ! -name 'README.md' | sort
```

- **孤儿页**：某页既没在 `index.md` 出现、也没被任何其它页 `[[链接]]` 引用 → 标记。
- **index 失配**：`index.md` 里列了但文件不存在（死链），或文件存在却没进 index（漏录）→ 标记。
- 用 `grep -rl "\[\[<page>\]\]" .sdd/knowledge` 反查引用关系。

**Acceptance**：得到孤儿页清单 + index 失配清单（双向：死链 + 漏录）。

### Step 2 — 矛盾检测

跨页比对对**同一主题**的论断是否冲突（同一模块两页说法不一、两条 lesson 给相反建议等）。按 tags / 关键词聚类相关页再逐对比对。

**Acceptance**：得到「疑似矛盾」页对清单，每对附冲突点摘要。

### Step 3 — 过时核验（对照当前代码，工程场景特有）

对 `lessons/` 与 `modules/` 抽查：页里引用的文件/接口/行为**在当前代码里是否还成立**（接口已改名、坑已被框架/依赖升级修复、模块已重构）。`grep` 页里提到的符号/路径到源码核对。

**Acceptance**：得到「疑似过时」页清单，每条注明依据（如「页称 `authConnect()`，代码已无此符号」）。

### Step 4 — 缺失交叉引用 + 规模红线

- **缺失交叉引用**：明显强相关的两页之间没有 `[[链接]]` → 建议补链。
- **规模红线**：粗算 `index.md` + 「常被一起召回的页」总 token（`wc -c` / 4）。逼近 **~50k token** → 告警，建议拆领域子 index 或归档过时页（见 schema §6）。

```bash
# index 体量粗估（token ≈ chars/4）
awk '{c+=length($0)} END{printf "index.md ~%d tokens\n", c/4}' .sdd/knowledge/index.md
```

**Acceptance**：得到补链建议清单 + 规模红线评估（当前 token 估算 + 是否告警）。

### Step 5 — 产出报告（不自动改）

汇总五类发现成一份结构化报告：每条含「问题 / 涉及页 / 建议动作」。**不自动删除/改写**——逐条让用户决定。可在用户确认后，再用 `kb-save` 风格做具体修复。**不碰 git。**

**Acceptance**：报告覆盖五类检查；每条有明确建议；未对知识库做任何破坏性自动修改。

## 输入

- 已存在的 `.sdd/knowledge/`（必需）。
- 当前项目源码（用于过时核验）。
- 可选：用户指定只 lint 某一类（如「只查孤儿页」）。

## 输出

- 一份**巡检报告**：①矛盾 ②过时 ③孤儿页 ④缺失交叉引用 ⑤规模红线，每条带涉及页 + 建议动作。
- **不自动删除/改写知识页、不动 git**——所有修复由用户确认后再做。

## 反模式

- ❌ 自动删孤儿页 / 自动改矛盾——删错或改错历史经验代价极大；本 skill 只报告与建议
- ❌ 只查 index 不核对实际文件——孤儿与死链是双向的，必须文件系统与 index 对照
- ❌ 过时核验只读知识页、不读当前代码——「是否还成立」必须对照真实源码，否则是空谈
- ❌ 规模红线只看页数不估 token——红线是 token 维度（~50k），用字符数粗算才有意义
- ❌ 报告含糊（「有些页可能过时」）——每条必须点名具体页 + 具体依据 + 具体建议动作
- ❌ 借 lint 之名顺手大改知识库——修改是用户确认后的独立动作，lint 本身只读 + 出报告

## 示例

```
用户：给知识库做个体检
Claude（本 skill）：
  [Step 1] 12 页；孤儿：patterns/early-return-guard（没进 index 也没被引用）
           index 失配：列了 lessons/foo 但文件已删（死链）
  [Step 2] 矛盾：modules/auth-service 说"令牌存 cookie"，
           decisions/use-jwt-over-session 说"令牌走 Authorization 头" → 冲突
  [Step 3] 过时：lessons/sqlite-locked-on-fork 引用 db.connect()，代码已改为 db.open() → 疑过时
  [Step 4] 缺链：lessons/sqlite-locked-on-fork ↔ modules/session-store 强相关却未互链
           规模：index ~3.2k token，远低于 50k 红线 ✓
  [Step 5] 报告（5 类，每条带建议）：
    - 孤儿 patterns/early-return-guard → 建议补进 index 或确认删除
    - 死链 lessons/foo → 建议从 index 移除该行
    - 矛盾 auth-service vs use-jwt → 建议核对当前实现后统一表述
    - 过时 sqlite-locked-on-fork → 建议把 db.connect() 更新为 db.open()
    - 缺链 → 建议双向补 [[链接]]
    （未自动改动，请逐条确认；确认后可让我用 kb-save 风格修复。未提交。）
```
