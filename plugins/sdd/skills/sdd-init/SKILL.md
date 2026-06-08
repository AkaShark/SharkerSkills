---
name: sdd-init
description: 在当前项目一键铺出 .sdd/ 脚手架——constitution.md（项目宪法/稳定层）、schema.md（知识库行为协议）、空的 knowledge/（modules/decisions/lessons/patterns 四类工程知识页 + index.md 召回入口）、specs/（SDD 流水线产物目录）。这是整条 Spec-Driven Development 流水线 + 自生长工程知识库的入口。当用户说「初始化 SDD / sdd init / 给这个项目装 SDD / 铺一套 spec 流水线 / 建知识库脚手架」时使用。
---

# sdd-init —— SDD 脚手架一键铺设

把一整套 **Spec-Driven Development 流水线 + 自生长工程知识库**的目录骨架铺进当前项目：一个 `.sdd/` 目录，含项目宪法、知识库行为协议、四类工程知识页的空容器、以及 specs 产物目录。铺完之后，`sdd-spec → sdd-design → sdd-tasks → sdd-impl` 就有了落脚点，知识库也能开始自我生长。**只铺目录、不写业务代码、不碰 git。**

> **借鉴透明标注（D2）**：脚手架一键 init 借鉴自 [cc-sdd](https://github.com/gotalab/cc-sdd)（原版 `npx cc-sdd@latest` 写入 `.kiro/` 结构）；我们改为纯 Claude Code skill（无 npm 依赖，贴合 SharkerSkills 纯文件分发），目录改为 `.sdd/`。宪法层借鉴 [spec-kit](https://github.com/github/spec-kit) 的 constitution，知识库借鉴 [karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)（详见各文件内标注与 `schema.md`）。

## 何时使用

- 「初始化 SDD」「sdd init」「给这个项目装上 SDD 流水线」
- 「铺一套 spec → design → tasks 的开发流程」
- 「建一个会自动积累的工程知识库脚手架」
- 一个新项目（或还没接入 SDD 的老项目）准备按规范化流程开发
- 用户想用 `sdd-spec` / `kb-query` 等，但项目里还没有 `.sdd/`

## 何时不使用

- 项目里**已存在 `.sdd/`** 且内容非空——本 skill 不覆盖既有脚手架（默认**跳过**：报告现状后 `exit 0`、非报错，避免抹掉已积累的知识库；用户确需重置时手动备份/删除 `.sdd/` 后再来）
- 用户只想**跑某个阶段**（已经有 `.sdd/`）——直接用 `sdd-spec` / `sdd-design` 等，不必重新 init
- 用户想把脚手架铺到 **SharkerSkills 这个 marketplace 仓库自身**——这里是 skill 的源仓库，不是被开发的业务项目，别在这 init
- 用户想要的是离散工具而非工作流——那是 `sharker-tool` / `sharker-common` 的范畴

## 依赖 / 工具

- **本 skill 自带 `assets/` 模板**（constitution / schema / knowledge 骨架 / specs），随 plugin 分发，加载时一并落到 plugin cache。
- `cp`、`find`、`perl`（做 `{{DATE}}` 占位替换，macOS/Linux 通用）、`date`——均系统自带。
- Claude `Bash`、`Read` 工具。无 npm / 无网络依赖。

> Claude 加载本 skill 时会得到一个「Base directory」路径（形如 `~/.claude/plugins/cache/sharker-skills/sharker-sdd/<version>/skills/sdd-init`）。**下文用 `$SKILL_DIR` 指代该路径**，实际执行时替换为完整路径，bash 中可 `SKILL_DIR=<base_dir>` 后续复用。

## 工作流程

### Step 1 — 解析目标项目根 & 前置校验

```bash
PROJECT="$(pwd -P)"                       # 默认铺到当前工作目录
ASSETS="$SKILL_DIR/assets"
[ -d "$ASSETS" ] || { echo "skill assets 缺失: $ASSETS" >&2; exit 1; }
```

- `PROJECT` 取当前 cwd（用户应已 `cd` 到目标项目）。若用户显式给了路径，用那个。
- **拒绝铺到 SharkerSkills 源仓库**：若 `PROJECT` 下存在 `.claude-plugin/marketplace.json`，停止并提示「这里是 skill 源仓库，不是业务项目，不在此 init」。
- **幂等守卫**：若 `$PROJECT/.sdd/` 已存在且非空，**不覆盖**，停止并报告现状（让用户决定是否手动清理后重来）。

```bash
[ -f "$PROJECT/.claude-plugin/marketplace.json" ] && { echo "REFUSE: 当前是 marketplace 源仓库，不在此 init。" >&2; exit 1; }
if [ -d "$PROJECT/.sdd" ] && [ -n "$(ls -A "$PROJECT/.sdd" 2>/dev/null)" ]; then
  echo "ALREADY: $PROJECT/.sdd 已存在且非空，跳过（不覆盖既有知识库）。"; exit 0
fi
```

**Acceptance**：`$ASSETS` 存在；`$PROJECT` 不是 marketplace 源仓库；`$PROJECT/.sdd/` 不存在或为空。任一不满足就停止。

### Step 2 — 拷贝脚手架并替换日期占位

```bash
TODAY="$(date +%F)"                        # YYYY-MM-DD
mkdir -p "$PROJECT/.sdd"
cp -R "$ASSETS/." "$PROJECT/.sdd/"         # 铺入 constitution/schema/knowledge/specs
# 把所有模板里的 {{DATE}} 占位换成今天（perl -i 在 macOS/Linux 行为一致）
find "$PROJECT/.sdd" -type f -name '*.md' -exec perl -pi -e "s/\{\{DATE\}\}/$TODAY/g" {} +
```

**Acceptance**：`$PROJECT/.sdd/constitution.md`、`schema.md`、`knowledge/index.md`、`knowledge/{modules,decisions,lessons,patterns}/`、`specs/` 都存在；`grep -rl '{{DATE}}' "$PROJECT/.sdd"` 为空（占位已全部替换）。

### Step 3 — 自检铺设结果

```bash
echo "=== .sdd/ 结构 ==="
find "$PROJECT/.sdd" -maxdepth 2 | sort
echo "=== 占位残留检查（应为空）==="
grep -rl '{{DATE}}' "$PROJECT/.sdd" || echo "无残留占位 ✓"
```

**Acceptance**：结构完整且无 `{{DATE}}` 残留。

### Step 4 — 注入知识库指针到项目 CLAUDE.md（让自主沉淀/召回真正触发；**非 hook**）

`.sdd/schema.md` 是给 AI 的行为协议，但它默认不在会话上下文里——AI 读不到就不会自主沉淀/召回。这一步往项目 `CLAUDE.md` **追加**一个**带标记、幂等、可整段删除**的指针块（只放协议摘要 + 指向 `schema.md`，**不灌全文**，保持「主 CLAUDE.md 不被 schema 正文污染」的原则）。这是**纯文本注入，不是 hook**：没有运行时拦截、没有后台进程、没有 `settings.json` 改动——看得见、删得掉。

```bash
CLAUDE_MD="$PROJECT/CLAUDE.md"
MARKER="sharker-sdd:knowledge-base"
if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
  echo "CLAUDE.md 已含知识库指针，跳过注入（幂等）"
else
  { [ -s "$CLAUDE_MD" ] && printf '\n'; cat "$SKILL_DIR/claude-md-pointer.tmpl.md"; } >> "$CLAUDE_MD"
  echo "已注入知识库指针 → $CLAUDE_MD（原文件不存在则已新建，仅追加不改写）"
fi
```

**Acceptance**：`$PROJECT/CLAUDE.md` 存在且含**且仅含一处** `sharker-sdd:knowledge-base` 标记块；已有 CLAUDE.md 的原内容只被**追加**、未被改写；二次 init 不重复注入。

### Step 5 — 给用户回执 + 引导下一步

报告铺出了什么，并提示：① 去 `constitution.md` 填项目稳定原则；② **已往 `CLAUDE.md` 加了一段带标记的知识库指针（不喜欢可整段删）**；③ 第一个 feature 用 `/sharker-sdd:sdd-spec` 开工；④ 知识库会随开发自动生长，随时 `/sharker-sdd:kb-query` 召回、`/sharker-sdd:kb-lint` 巡检。**不替用户 git add/commit。**

**Acceptance**：回执说明了 `.sdd/` 各部分用途 + CLAUDE.md 注入 + 下一步命令；未执行任何 git 操作。

## 输入

- **目标项目根**（默认当前 cwd；用户可显式指定绝对路径）。无需其它参数。
- 前提：用户已在要装 SDD 的项目目录里（不是 SharkerSkills 源仓库、不是 Claude Code 缓存目录）。

## 输出

在 `$PROJECT/.sdd/` 下铺出：

```
.sdd/
├── constitution.md          项目宪法（稳定层，待用户填）
├── schema.md                知识库行为协议（AI 读，定义怎么维护 knowledge/）
├── specs/                   SDD 流水线产物（spec/design/tasks 按 feature 分目录）
│   └── README.md
└── knowledge/               自生长工程知识库
    ├── index.md             召回入口（清单 + 一句话摘要 + 规模红线）
    ├── modules/             模块实体页
    ├── decisions/           架构决策记录
    ├── lessons/             踩坑教训
    └── patterns/            代码模式/约定
```

文件内 `{{DATE}}` 已替换为当天日期。

并在项目 `CLAUDE.md` **追加**一个带标记的知识库指针块（`<!-- sharker-sdd:knowledge-base ... -->`，幂等、可整段删除）——让 AI 每个会话都能把行为协议读进上下文，自主沉淀/召回才会真正触发。**这是纯文本注入，不是 hook。**

**不产生业务代码、不动 git。**

## 反模式

- ❌ 覆盖已存在的 `.sdd/`——里面可能已积累几十页知识，抹掉就是灾难；非空一律跳过，让用户显式决定
- ❌ 在 SharkerSkills 源仓库里 init——那是 skill 的「工厂」，不是「车间」；铺进去毫无意义还会污染仓库
- ❌ 用 `sed -i` 做占位替换——macOS/GNU 的 `-i` 语法不一致；统一用 `perl -pi -e` 跨平台
- ❌ 手动逐个 `Write` 重建模板——模板是 `assets/` 里的权威拷贝，只 `cp` 不重写，避免漂移
- ❌ init 完顺手 `git add` / `git commit`——本 skill 不碰 git，交还用户
- ❌ 把日期写死在模板里——模板用 `{{DATE}}` 占位，init 时才注入当天日期
- ❌ 把整个 `schema.md` 正文灌进 `CLAUDE.md`——只注入**摘要+指针**，全文留在 `.sdd/schema.md`，守住「不污染主 CLAUDE.md」原则
- ❌ 用 hook（Stop/SessionEnd 拦截）做这件事——本 skill 走纯文本注入，无运行时侵入；不喜欢可删整块
- ❌ 注入不加标记 / 不查重——必须用 `sharker-sdd:knowledge-base` 标记保证幂等，二次 init 不重复追加

## 示例

**示例 1（happy path）**

```
用户：给这个项目初始化一下 SDD
Claude（本 skill）：
  [Step 1] cwd=/Users/me/proj，非 marketplace，.sdd/ 不存在 ✓
  [Step 2] cp assets → .sdd/，替换 {{DATE}} → 2026-06-08
  [Step 3] 自检：结构完整、无占位残留 ✓
  [Step 4] CLAUDE.md 无标记 → 追加知识库指针块（带标记、可删）✓
  [Step 5] 回执：
    ✅ 已铺出 .sdd/（constitution / schema / knowledge/ / specs/）
    ✅ 已往 CLAUDE.md 追加知识库指针（标记块，不喜欢可整段删）
    下一步：
      1. 编辑 .sdd/constitution.md 填项目稳定原则
      2. 第一个 feature 用 /sharker-sdd:sdd-spec
      3. 开发中知识自动沉淀，可 /sharker-sdd:kb-query 召回
    （未动 git，提交请自行 git add .sdd/ CLAUDE.md）
```

**示例 2（已存在，跳过）**

```
用户：再 init 一次
Claude（本 skill）：
  [Step 1] .sdd/ 已存在且非空 → ALREADY，跳过
  回执：检测到 .sdd/ 已有内容（含 knowledge/，可能已积累知识页）。
       为防覆盖未重新铺设。如确需重置，请手动备份/删除 .sdd/ 后再来。
```
