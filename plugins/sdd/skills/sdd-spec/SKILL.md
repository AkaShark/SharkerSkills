---
name: sdd-spec
description: SDD 流水线第一阶段——把一句话需求结构化为 specs/<feature>/spec.md（目标 + 用户故事 + EARS 格式验收标准 + 非目标）。开头先召回工程知识库（读 .sdd/knowledge/index.md 找历史相关坑/决策），避免重蹈覆辙。当用户说「写个 spec / sdd spec / 给这个需求做规格 / 把需求结构化 / 开始一个新 feature」且项目已有 .sdd/ 时使用。
---

# sdd-spec —— 需求 → 规格

把一句话需求打磨成一份结构化 `spec.md`：**要做什么、给谁用、做到什么程度算完成（验收标准）、明确不做什么**。这是 SDD 纵向流水线的第一棒，也是横向知识复利的召回触发点——**动笔前先问知识库「这个 feature 历史上有没有相关的坑或决策」**。

> **借鉴透明标注（D2）**：阶段链 spec→design→tasks→impl 借鉴 [cc-sdd](https://github.com/gotalab/cc-sdd)（原版 `/kiro-spec-init` → requirements，用 EARS 格式）；我们裁剪为 skill、存 `.sdd/specs/`。验收用 **EARS 格式**（`When <条件>, the system shall <行为>`）借鉴自 cc-sdd，本 skill **推荐不强制**。开头召回知识库是本项目的紧耦合设计（见 `.sdd/schema.md` §7）。

## 何时使用

- 「写个 spec」「sdd spec」「给这个需求做规格」
- 「开始一个新 feature，先把需求理清楚」
- 「把这段模糊需求结构化成验收标准」
- 项目已有 `.sdd/`，准备开一个新 feature 走 SDD 流程

## 何时不使用

- 项目里**还没有 `.sdd/`**——先用 `sdd-init`
- 需求已经有清晰 spec.md，用户想往下走——直接用 `sdd-design`
- 一次性小改 / 改个文案 / 修个明显 bug——杀鸡用牛刀，直接改即可
- 用户要的是纯头脑风暴而非可验收的规格——先聊清楚再回来

## 依赖 / 工具

- 已存在的 `.sdd/`（尤其 `knowledge/index.md` 与 `schema.md`）。
- Claude `Read`、`Write`、`Bash`、`Grep` 工具。无外部依赖。

## 工作流程

### Step 1 — 召回知识库（紧耦合·开头必做）

按 `.sdd/schema.md` §4 的 Query 流程召回，**别跳过**：

```bash
test -f .sdd/knowledge/index.md || { echo "未找到 .sdd/knowledge/index.md，先 sdd-init" >&2; exit 1; }
```

1. **读 `.sdd/knowledge/index.md`**（召回唯一入口）。
2. 用需求里的关键词 / 领域 tags，判断哪几页相关；必要时 `grep -ri "<关键词>" .sdd/knowledge/` 补定位。
3. **只读命中的那几页**（lessons/decisions/modules/patterns）。
4. 同时读 `.sdd/constitution.md`（稳定原则约束本 spec）。

**Acceptance**：已读 index.md + constitution.md；若有命中页，已读其正文并能在后续引用。无命中也要显式说明「知识库暂无相关历史」。

### Step 2 — 澄清（可选 clarify 环节）

若需求有**关键歧义**（影响验收的范围/边界/优先级），用 1 次 `AskUserQuestion` 集中提问降返工；无歧义则跳过。

> 借鉴 spec-kit 的 `/speckit.clarify`（原版在 plan 前结构化提问）；我们**内联**为本 skill 的可选 Step，不单列 skill。

**Acceptance**：要么无歧义直接进 Step 3，要么已通过提问消除影响验收的歧义。

### Step 3 — 起草 spec.md

确定 feature 短名 `<feat>`（kebab-case），写到 `.sdd/specs/<feat>/spec.md`，含五块：

1. **目标**：一两句话说清要解决什么问题。
2. **用户故事**：`作为 <角色>，我想 <能力>，以便 <价值>`。
3. **验收标准**：逐条可测；**推荐 EARS 格式** `When <触发/条件>, the system shall <可观察行为>`（也可用 Given/When/Then）。
4. **非目标**：明确这次**不做**什么，划清边界。
5. **知识库召回小结**：把 Step 1 命中的历史坑/决策列出来（带 `[[链接]]`），说明本 spec 如何规避/沿用。无命中则写「知识库暂无相关历史」。

**Acceptance**：`spec.md` 五块齐全；验收标准每条可测；含召回小结（即便为空也显式写出）。

### Step 4 — 回执 + 引导

报告 spec 路径与要点，提示下一步 `/sharker-sdd:sdd-design`。**不碰 git。**

**Acceptance**：用户拿到 spec 路径 + 验收标准摘要 + 下一步命令。

## 输入

- **一句话（或一段）需求描述**（必需）。
- **feature 短名**（可从需求提炼，kebab-case；不确定时问用户）。
- 已存在的 `.sdd/knowledge/`、`.sdd/constitution.md`。

## 输出

- `.sdd/specs/<feat>/spec.md`，含目标 / 用户故事 / EARS 验收 / 非目标 / 知识库召回小结。
- **不产生代码、不写 design、不动 git。**

## 反模式

- ❌ 跳过 Step 1 召回直接写 spec——这就把「知识复利」这条横向价值链断了，等于退回普通 SDD
- ❌ 验收标准写成不可测的形容词（「体验流畅」「性能好」）——必须可观察、可判定
- ❌ 把 design（架构/技术方案）混进 spec——spec 只回答「做什么/验收」，「怎么做」留给 sdd-design
- ❌ 漏写非目标——边界不划清，scope 会在 impl 阶段悄悄膨胀
- ❌ 召回小结即便为空也省略——显式写「无相关历史」本身就是有价值的信号

## 示例

```
用户：给「用户登录」写个 spec
Claude（本 skill）：
  [Step 1] 读 index.md → grep "auth/login/token"
           命中 lessons/oauth-token-refresh-race ⇒ 读其正文
  [Step 2] 澄清：支持第三方登录吗？→ 用户：只做邮箱+密码
  [Step 3] 写 .sdd/specs/user-login/spec.md
           · 验收(EARS)：When 用户提交正确邮箱密码, the system shall 返回会话令牌并跳转首页
           · 非目标：本期不做第三方/OAuth 登录
           · 召回小结：历史有 token 刷新竞态坑 [[lessons/oauth-token-refresh-race]]，
             本期无刷新逻辑，暂不受影响，design 阶段如引入需复核
  [Step 4] 回执：spec 就绪 → 下一步 /sharker-sdd:sdd-design
```
