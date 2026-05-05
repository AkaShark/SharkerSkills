---
name: skill-creator
description: 在 SharkerSkills plugin 内交互式创建一个全新的 skill —— 通过 8 轮问答收集名称/触发/输入/输出/示例，生成符合规范的 SKILL.md，并自动 minor-bump plugin 三站点 version 与 README 目录。当用户说"创建新 skill / 新建 skill / 帮我做一个 skill / generate skill / new skill / 加一个 skill"等意图时使用。
---

# Skill Creator —— SharkerSkills 的 meta-skill

通过结构化访谈生成一个新的、可立即被 Claude Code 加载的 skill，并把它接入本 plugin 的 manifest 与 README 目录。**只生成文件、只改 manifest，不做 git commit、不做 git push、不做 smoke test**——这些动作交还给用户。

## 何时使用

- "帮我加一个 skill / 新建一个 skill / 创建 skill"
- "generate a new skill / new skill / make me a skill"
- 用户描述了一个想要复用的工作流，希望从零规划并沉淀为本 plugin 内的常驻 skill
- 用户已经在 SharkerSkills **工作 git 仓库**里（cwd 包含 `.claude-plugin/marketplace.json`），**不是** Claude Code 维护的 marketplace 缓存目录

## 何时不使用

- 用户只是想让你**执行一次**某个任务（直接做即可，不要建 skill）
- **如果你已经在和 Claude 进行的对话里把工作流跑通过**，更适合用 `oh-my-claudecode:skillify` 从对话中抽取 skill；本 skill 适合"从零规划"，skillify 适合"从对话回收"
- 用户已经知道答案、不需要交互式收集（直接手写 SKILL.md 更快）
- 用户想修改用户全局 skills 目录下的 skill（本 skill 只动 plugin 内 `skills/`）
- 用户想生成多文件 skill（带 `scripts/` `refs/` `assets/`）—— 当前版本只支持单文件 SKILL.md
- 用户想引入第三方 skill 并保留对方 LICENSE —— 走 README 里的"添加新 skill"手动流程

## 依赖 / 工具

- `jq`（macOS 自带）—— 安全编辑 JSON
- Claude `AskUserQuestion`、`Write`、`Edit`、`Bash` 工具

## 前置检查（动手前必做）

> **核心原则**：本 skill 永远写到用户的**工作 git 仓库**（如 `~/Desktop/Project/.../SharkerSkills/`），**绝不**写到 Claude Code 内部的 marketplace 缓存目录（`~/.claude/plugins/marketplaces/sharker-skills/` 或 `${CLAUDE_CONFIG_DIR}/plugins/marketplaces/...`）。缓存目录是 Claude Code 自己维护的拷贝，写进去的改动既不会进 git，也会被下次 `marketplace add/update` 覆盖。

1. **解析目标仓库路径 `<repo>`**（按优先级取第一项）：
   - 用户在调用本 skill 时显式指定的路径参数
   - 当前 cwd（`pwd` 取得），如果它**同时**满足 (a) 包含 `.claude-plugin/marketplace.json` 与 `.claude-plugin/plugin.json`、(b) **不**位于 `~/.claude/plugins/marketplaces/`、`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/` 任意子路径下
   - 否则用一次 `AskUserQuestion` 让用户输入工作仓库的绝对路径，**不要**自作聪明从 cache 推断
2. **拒绝 cache 路径**：执行
   ```bash
   case "$(pwd -P)" in
     "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/*) echo "FATAL: 禁止写入 Claude Code 缓存目录" >&2; exit 1 ;;
     "$HOME"/.claude/plugins/*) echo "FATAL: 禁止写入 Claude Code 缓存目录" >&2; exit 1 ;;
   esac
   ```
   命中即报错并退出："当前目录是 Claude Code 维护的 marketplace 缓存，本 skill 拒绝在此写入。请 `cd` 到 SharkerSkills 工作 git 仓库（你 git push 的那一份）后重试。"
3. **校验工作仓库**：在解析得到的 `<repo>` 下，必须存在 `.claude-plugin/marketplace.json`、`.claude-plugin/plugin.json`，并且 `git rev-parse --is-inside-work-tree`（在 `<repo>` 内执行）返回 `true`。任一失败 → 报错退出。
4. **后续所有路径以 `<repo>` 为根**：bump、写 SKILL.md、追 README、idempotency 检查全部用 `<repo>/...` 绝对前缀。**禁止**用裸 `.claude-plugin/...` 相对路径让 cwd 决定写到哪。
5. **读取当前版本**：`jq -r .version "<repo>/.claude-plugin/plugin.json"` → 记为 `<current_version>`。

> **同步到缓存由用户负责**：写完工作仓库后，用户需要 `git commit && git push`，再用 `/plugin marketplace update sharker-skills`（或重装）让 Claude Code 拉新版本进 cache。本 skill 不替用户做这一步。

## 工作流程（**8 轮 AskUserQuestion**）

**总规则**：
- 一次只问一题，使用 `AskUserQuestion`；提供 2–4 个可点选项 + free-text。
- **校验失败时重试同一题**：重新调用同一个 `AskUserQuestion`，把 `[校验失败：<原因>]` 加在 question 文本最前面。**不要重启整个访谈**。
- 校验通过才进入下一题。

### Step 1 — Q1: 新 skill 的 kebab-case 名称

- Prompt: "新 skill 叫什么名字？（kebab-case，如 `swift-snapshot-tester`）"
- 校验 1（正则）: `echo "<answer>" | grep -E '^[a-z][a-z0-9-]*$'`，失败 → `[校验失败：名称必须 kebab-case，以小写字母开头，只含 a-z/0-9/-]`
- 校验 2（**case-insensitive 目录碰撞**）: `find skills -maxdepth 1 -type d -iname "<answer>" | grep -q .`，命中 → `[校验失败：skills/ 下已存在大小写匹配的同名目录，本 skill 不会覆盖既有 skill；请改名]`
- 通过后存为 `<name>`。
- **Acceptance**: `<name>` 满足正则且 `skills/<name>/` 不存在（case-insensitive）。

### Step 2 — Q2: frontmatter description

- Prompt: "用一句中文描述这个 skill 是干什么的、什么时候触发？这句话进 frontmatter `description`，决定 Claude Code 何时自动加载它。"
- 存为 `<description>`。

### Step 3 — Q3: 输出目录确认

- Prompt: "把新 skill 写到 `skills/<name>/SKILL.md` 吗？"
- Options: ["是，使用默认路径", "否，输入绝对路径"]
- 默认 `skills/<name>/SKILL.md`，存为 `<target_path>`。

### Step 4 — Q4: 何时使用（触发短语）

- Prompt: "列出 3–6 条用户可能说的触发短语（中英混合都可）。"
- 存为 `<use_when_lines>`（数组）。

### Step 5 — Q5: 输入与上下文

- Prompt: "运行这个 skill 时，Claude 需要从用户那拿到什么？需要读哪些文件 / 项目结构？"
- 存为 `<inputs>`。

### Step 6 — Q6: 输出与产物

- Prompt: "skill 跑完会产出什么？写到哪里？"
- 存为 `<outputs>`。

### Step 7 — Q7: 外部工具 / 命令（可选）

- Prompt: "skill 内部会调用哪些命令或外部工具？（如 `xcodebuild`、`gh`、`sips`，可填『无』）"
- 存为 `<tools>`。

### Step 8 — Q8: 1–2 个使用示例（可选）

- Prompt: "给 1–2 个简短的使用示例（一行一个）。可填『暂无』。"
- 存为 `<examples>`。

## 生成的 SKILL.md 模板（10 节，对齐 ios-store-assets）

8 题访谈完成后，用 `Write` 把以下模板渲染到 `<target_path>`。`## 工作流程`、`## 反模式` 由 LLM 根据 Q5/Q6/Q7 综合写出，**不要照搬用户原话**。

```markdown
---
name: <name>
description: <description>
---

# <name>

<一句话 tagline，从 description 提炼>

## 何时使用
- <use_when_lines[0]>
- <use_when_lines[1]>
- ...（3–6 条）

## 何时不使用
- <反触发场景 1：基于 Q5/Q6 推断>
- <反触发场景 2>
- 用户已经知道答案、不需要本 skill 的结构化流程
- （≥2 条）

## 依赖 / 工具
<tools>（若 Q7 = "无"，写"无外部依赖；纯 Claude 工具调用即可。"）

## 工作流程
### Step 1 — <名称>
…
**Acceptance**: <可验证条件>

### Step 2 — <名称>
…
**Acceptance**: <可验证条件>

（共 3–6 步）

## 输入
<inputs>

## 输出
<outputs>

## 反模式
- <反模式 1：本 skill 实现/调用时易踩的坑>
- <反模式 2>
- （≥2 条）

## 示例
<examples>
```

## Post-Generation 文件 Mutation（**先 bump version、后写文件**）

**重要**：先做版本 bump，再写 SKILL.md 与 README。理由：bump 失败时整个仓库未触动；后续写文件失败时只需 `rm -rf skills/<name>/` 加 `git checkout README.md` 即可全回滚。

### Mutation 1 — 原子三站点 version bump（minor +1）

```bash
cd "<repo>" || { echo "FATAL: 工作仓库 <repo> 不存在" >&2; exit 1; }
CURRENT=$(jq -r .version .claude-plugin/plugin.json)
NEW=$(echo "$CURRENT" | awk -F. '{printf "%d.%d.%d", $1, $2+1, 0}')
echo "$CURRENT -> $NEW"

# Stage to /tmp
jq --arg v "$NEW" '.version=$v' .claude-plugin/plugin.json > /tmp/plugin.json.new
jq --arg v "$NEW" '.version=$v | .plugins[0].version=$v' .claude-plugin/marketplace.json > /tmp/marketplace.json.new

# Validate parse
jq empty /tmp/plugin.json.new && jq empty /tmp/marketplace.json.new || {
  echo "STAGE FAIL: 临时文件 jq 解析失败，已中止；未触动原文件。"
  rm -f /tmp/plugin.json.new /tmp/marketplace.json.new
  exit 1
}

# Atomic move
mv /tmp/plugin.json.new .claude-plugin/plugin.json
mv /tmp/marketplace.json.new .claude-plugin/marketplace.json

# Post-write verify
[ "$(jq -r .version .claude-plugin/plugin.json)" = "$NEW" ] && \
[ "$(jq -r .version .claude-plugin/marketplace.json)" = "$NEW" ] && \
[ "$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)" = "$NEW" ] || {
  echo "POST-WRITE MISMATCH: 三站点版本不一致。"
  echo "请手动回滚（本 skill 不自动执行 git）：git checkout .claude-plugin/"
  exit 1
}
echo "version OK: $NEW (3 sites)"
```

### Mutation 2 — 写新 skill SKILL.md

`mkdir -p <target_path>` 的父目录后用 `Write` 写完整 10 节模板。

### Mutation 3 — 在 README "Skill 目录" 表格追加一行

**Idempotency 守卫**先跑：

```bash
grep -q "skills/<name>/SKILL.md" README.md && { echo "README 已含 <name>，跳过追加"; SKIP_README=1; }
```

未跳过时，**清洗 description**（避免破坏表格）：
- strip newlines（替换为空格）
- escape `|` 为 `\|`
- 截断到 ≤120 字符（超出加 `…`）

得到 `<safe_description>` 后用 `Edit`：
- `old_string` = README 当前 "Skill 目录" 表格的最后一行（以 `|` 开头）
- `new_string` = 旧行 + `\n| [` + `<name>` + `](./skills/` + `<name>` + `/SKILL.md) | ` + `<safe_description>` + ` |`

回退锚点：若 `old_string` 非唯一，用 `## 添加新 skill` 之前最后一个 `|` 开头行。

## Validation（提交给用户前必跑）

### Inline Row 10 — version 三站点一致

```bash
[ "$(jq -r .version .claude-plugin/marketplace.json)" = "$(jq -r .version .claude-plugin/plugin.json)" ] && \
[ "$(jq -r .version .claude-plugin/marketplace.json)" = "$(jq -r .plugins[0].version .claude-plugin/marketplace.json)" ] && \
echo "Row 10 OK: 三站点版本 = $(jq -r .version .claude-plugin/plugin.json)"
```

失败 → 提示 `git checkout .claude-plugin/` 回滚（不自动执行），停止。

### 新 skill frontmatter sanity

```bash
head -5 skills/<name>/SKILL.md | grep -E "^name: <name>$" && \
head -5 skills/<name>/SKILL.md | grep -E "^description: "
```

### 完整 14 行验收（建议用户在 commit 前跑）

完整命令在 `.omc/plans/sharker-skills-bootstrap.md` Step 7 表格。涉及：JSON parse、required keys、no `mcpServers`、no `$schema` on plugin.json、SKILL portable、`.omc/` tracked、README install block、`category=productivity`、kebab name lock-step、LICENSE/SPDX。

## 完成后给用户的 Next-Step 提示

```
新 skill `<name>` 已生成：
  • <target_path>
  • plugin 版本 <CURRENT> → <NEW>（3 站点已校验）
  • README "Skill 目录" 已追加一行

请手动完成下列动作（本 skill 不替你做）：

1. 跑完整 14 行验收（.omc/plans/sharker-skills-bootstrap.md Step 7 表格）
2. 在干净 Claude Code 会话 smoke test：
     /plugin marketplace add /path/to/SharkerSkills  # 或 AkaShark/SharkerSkills 公网版
     /plugin install sharker-skills@sharker-skills
     /reload-plugins
3. 提交并推送：
     git add skills/<name> .claude-plugin README.md
     git commit -m "feat(<name>): add <name> skill, bump to v<NEW>"
     git push
```

## 反模式

- ❌ 用 `sed` 改 JSON（脆弱、易破坏格式）—— 始终用 `jq` + temp file + atomic mv
- ❌ 在 8 题访谈未走完前就开始写文件 —— 必须**先 bump version 再写 skill 文件**
- ❌ 自动 `git checkout` 或 `git commit` —— 本 skill 永远不动 git，只**打印**回滚命令
- ❌ 直接把用户原话灌入生成模板的 `## 工作流程` —— 必须由 LLM 结构化为编号步骤 + Acceptance
- ❌ 跳过 case-insensitive 碰撞检测 —— macOS 默认 case-insensitive，会静默覆盖
- ❌ 写入 Claude Code marketplace 缓存目录（`~/.claude/plugins/marketplaces/...`）—— 那是 Claude 自己维护的副本，写进去既不会进 git，也会被下次 `marketplace update` 抹掉。永远写到用户的工作 git 仓库。

## 失败模式 & 拒绝清单

| 场景 | 行为 |
|---|---|
| 名称非 kebab-case | 重 Q1，前缀 `[校验失败：…]` |
| `skills/<name>/` 已存在（case-insensitive） | 重 Q1，前缀 `[校验失败：目录已存在]` |
| cwd 不是 plugin 根 | 拒绝并退出 |
| cwd 在 `~/.claude/plugins/` 或 `${CLAUDE_CONFIG_DIR}/plugins/` 之下（marketplace 缓存） | 拒绝并退出："禁止写入 Claude Code 缓存；请 `cd` 到工作 git 仓库后重试。" |
| 工作仓库不是 git 仓库（`git rev-parse --is-inside-work-tree` 失败） | 拒绝并退出 |
| STAGE FAIL（临时文件 jq 解析失败） | 中止；原文件未触动 |
| POST-WRITE MISMATCH | 中止；**打印** `git checkout .claude-plugin/`（不自动执行） |
| 用户要 git commit / push | 拒绝："本 skill 不做 git 操作；请手动跑 next-step 三条命令。" |
| 用户要多文件 skill | 拒绝："当前版本只支持单文件 SKILL.md（v0.3+ 计划支持）。" |
| 用户要改用户全局 skills 目录 | 拒绝："本 skill 只动 plugin 内 `skills/`。" |
| 用户已在对话里跑通工作流 | 引导："改用 `oh-my-claudecode:skillify` 从对话中抽取。" |

## 示例

**触发**：
```
用户：帮我加一个 skill，做 swift snapshot test 的
Claude（本 skill）：
  Q1: 新 skill 叫什么名字？kebab-case，例如 swift-snapshot-tester
  → 用户输：swift-snapshot-tester ✓
  Q2: 用一句中文描述...
  → ...
  （共 8 题）
  → 写 skills/swift-snapshot-tester/SKILL.md
  → bump 0.2.0 → 0.3.0
  → README 追加新行
  → 给出 commit/push 提示
```

## 设计自洽性（meta-note）

本 SKILL.md 自身就是用本 skill 生成出的形态——10 节结构、8 题访谈、frontmatter、依赖、工作流、反模式、拒绝清单——可作为新 skill 的参考样本。
