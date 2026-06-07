---
name: skill-creator
description: 在 SharkerSkills marketplace 内交互式创建一个全新的 skill —— 通过 9 轮问答收集名称/所属 plugin/触发/输入/输出/示例，生成符合规范的 SKILL.md，写入对应分类 plugin（sharker-common / sharker-ios / sharker-tool），并自动 minor-bump 该 plugin 的两站点 version 与更新 README 目录。当用户说"创建新 skill / 新建 skill / 帮我做一个 skill / generate skill / new skill / 加一个 skill"等意图时使用。
---

# Skill Creator —— SharkerSkills 的 meta-skill

通过结构化访谈生成一个新的、可立即被 Claude Code 加载的 skill，把它放进本 marketplace 里**用户指定的某个分类 plugin**，并接入该 plugin 的 manifest 与 README 目录。**只生成文件、只改 manifest，不做 git commit、不做 git push、不做 smoke test**——这些动作交还给用户。

## 何时使用

- "帮我加一个 skill / 新建一个 skill / 创建 skill"
- "generate a new skill / new skill / make me a skill"
- 用户描述了一个想要复用的工作流，希望从零规划并沉淀为本 marketplace 内某个分类 plugin 的常驻 skill
- 用户已经在 SharkerSkills **工作 git 仓库**里（cwd 包含 `.claude-plugin/marketplace.json`），**不是** Claude Code 维护的 marketplace 缓存目录

## 何时不使用

- 用户只是想让你**执行一次**某个任务（直接做即可，不要建 skill）
- **如果你已经在和 Claude 进行的对话里把工作流跑通过**，更适合用 `oh-my-claudecode:skillify` 从对话中抽取 skill；本 skill 适合"从零规划"，skillify 适合"从对话回收"
- 用户已经知道答案、不需要交互式收集（直接手写 SKILL.md 更快）
- 用户想修改用户全局 skills 目录下的 skill（本 skill 只动 marketplace 内 `plugins/*/skills/`）
- 用户想**新建一个 plugin 分类**（当前 sharker-common / sharker-ios / sharker-tool 之外）—— 本 skill 只往**已存在的 plugin** 里加 skill；新建 plugin 需手动 scaffold（建目录 + 写 plugin.json + 在 marketplace.json `plugins[]` 加条目）
- 用户想生成多文件 skill（带 `scripts/` `refs/` `assets/`）—— 当前版本只支持单文件 SKILL.md
- 用户想引入第三方 skill 并保留对方 LICENSE —— 走 README 里的"添加新 skill"手动流程

## 依赖 / 工具

- `jq`（macOS 自带）—— 安全编辑 JSON
- Claude `AskUserQuestion`、`Write`、`Edit`、`Bash` 工具

## 仓库结构（多 plugin 模型）

```
SharkerSkills/
  .claude-plugin/marketplace.json        # 目录：plugins[] 列出 N 个分类 plugin（无根 plugin.json）
  plugins/
    common/.claude-plugin/plugin.json    # name: sharker-common
            skills/<skill>/SKILL.md
    ios/.claude-plugin/plugin.json        # name: sharker-ios
            skills/<skill>/SKILL.md
    tool/.claude-plugin/plugin.json       # name: sharker-tool
            skills/<skill>/SKILL.md
  README.md
```

**版本模型**：每个 plugin 有**独立版本**，存在于 **2 站点**：
1. `<plugin_dir>/.claude-plugin/plugin.json` 的 `.version`
2. `marketplace.json` 中 `.plugins[] | select(.name==<plugin>) | .version`

marketplace 顶层 `.version` 是独立的目录版本，**本 skill 不动它**。

## 前置检查（动手前必做）

> **核心原则**：本 skill 永远写到用户的**工作 git 仓库**（如 `~/Desktop/Project/.../SharkerSkills/`），**绝不**写到 Claude Code 内部的 marketplace 缓存目录（`~/.claude/plugins/marketplaces/sharker-skills/` 或 `${CLAUDE_CONFIG_DIR}/plugins/marketplaces/...`）。缓存目录是 Claude Code 自己维护的拷贝，写进去的改动既不会进 git，也会被下次 `marketplace add/update` 覆盖。

1. **解析目标仓库路径 `<repo>`**（按优先级取第一项）：
   - 用户在调用本 skill 时显式指定的路径参数
   - 当前 cwd（`pwd` 取得），如果它**同时**满足 (a) 包含 `.claude-plugin/marketplace.json`、(b) **不**位于 `~/.claude/plugins/marketplaces/`、`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/` 任意子路径下
   - 否则用一次 `AskUserQuestion` 让用户输入工作仓库的绝对路径，**不要**自作聪明从 cache 推断
2. **拒绝 cache 路径**：执行
   ```bash
   case "$(pwd -P)" in
     "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/*) echo "FATAL: 禁止写入 Claude Code 缓存目录" >&2; exit 1 ;;
     "$HOME"/.claude/plugins/*) echo "FATAL: 禁止写入 Claude Code 缓存目录" >&2; exit 1 ;;
   esac
   ```
   命中即报错并退出："当前目录是 Claude Code 维护的 marketplace 缓存，本 skill 拒绝在此写入。请 `cd` 到 SharkerSkills 工作 git 仓库（你 git push 的那一份）后重试。"
3. **校验工作仓库**：在解析得到的 `<repo>` 下，必须存在 `.claude-plugin/marketplace.json`，并且 `git rev-parse --is-inside-work-tree`（在 `<repo>` 内执行）返回 `true`。任一失败 → 报错退出。
   > 注意：多 plugin 模型下**根目录不再有 `.claude-plugin/plugin.json`**，只有 `marketplace.json`。不要再把根 plugin.json 当作必需标记。
4. **读取可选 plugin 清单**：`jq -r '.plugins[].name' "<repo>/.claude-plugin/marketplace.json"` → 记为 `<plugin_names>`（如 `sharker-common` / `sharker-ios` / `sharker-tool`）。Q3 的选项**动态**由此生成，不要写死。
5. **后续所有路径以 `<repo>` 为根**：bump、写 SKILL.md、追 README、idempotency 检查全部用 `<repo>/...` 绝对前缀。**禁止**用裸相对路径让 cwd 决定写到哪。

> **同步到缓存由用户负责**：写完工作仓库后，用户需要 `git commit && git push`，再用 `/plugin marketplace update sharker-skills`（或重装）让 Claude Code 拉新版本进 cache。本 skill 不替用户做这一步。

## 工作流程（**9 轮 AskUserQuestion**）

**总规则**：
- 一次只问一题，使用 `AskUserQuestion`；提供 2–4 个可点选项 + free-text。
- **校验失败时重试同一题**：重新调用同一个 `AskUserQuestion`，把 `[校验失败：<原因>]` 加在 question 文本最前面。**不要重启整个访谈**。
- 校验通过才进入下一题。

### Step 1 — Q1: 新 skill 的 kebab-case 名称

- Prompt: "新 skill 叫什么名字？（kebab-case，如 `swift-snapshot-tester`）"
- 校验 1（正则）: `echo "<answer>" | grep -E '^[a-z][a-z0-9-]*$'`，失败 → `[校验失败：名称必须 kebab-case，以小写字母开头，只含 a-z/0-9/-]`
- 校验 2（**跨 plugin、case-insensitive 目录碰撞**）: `find plugins/*/skills -maxdepth 1 -type d -iname "<answer>" | grep -q .`，命中 → `[校验失败：某个 plugin 的 skills/ 下已存在大小写匹配的同名目录，skill 名需全仓唯一；请改名]`
- 通过后存为 `<name>`。
- **Acceptance**: `<name>` 满足正则且任何 `plugins/*/skills/<name>/` 都不存在（case-insensitive）。

### Step 2 — Q2: frontmatter description

- Prompt: "用一句中文描述这个 skill 是干什么的、什么时候触发？这句话进 frontmatter `description`，决定 Claude Code 何时自动加载它。"
- 存为 `<description>`。

### Step 3 — Q3: 归属哪个 plugin（**新增，多 plugin 模型核心**）

- Prompt: "这个 skill 归到哪个分类 plugin？"
- Options: **动态**由 `<plugin_names>` 生成（如 `sharker-common`（meta/通用）、`sharker-ios`（iOS/Apple）、`sharker-tool`（独立工具）），外加 free-text。
- 校验（必须命中已存在 plugin）: `jq -e --arg n "<answer>" '.plugins[]|select(.name==$n)' .claude-plugin/marketplace.json >/dev/null`，失败 → `[校验失败：<answer> 不是已存在的 plugin；本 skill 只往现有 plugin 加 skill。新建 plugin 请手动 scaffold]`
- 通过后存为 `<plugin>`，并解析其目录：
  ```bash
  PLUGIN_DIR=$(jq -r --arg n "<plugin>" '.plugins[]|select(.name==$n).source' .claude-plugin/marketplace.json)
  ```
  存为 `<plugin_dir>`（如 `./plugins/ios`）。
- **Acceptance**: `<plugin>` ∈ `<plugin_names>` 且 `<plugin_dir>/.claude-plugin/plugin.json` 存在。

### Step 4 — Q4: 输出目录确认

- Prompt: "把新 skill 写到 `<plugin_dir>/skills/<name>/SKILL.md` 吗？"
- Options: ["是，使用默认路径", "否，输入绝对路径"]
- 默认 `<plugin_dir>/skills/<name>/SKILL.md`，存为 `<target_path>`。

### Step 5 — Q5: 何时使用（触发短语）

- Prompt: "列出 3–6 条用户可能说的触发短语（中英混合都可）。"
- 存为 `<use_when_lines>`（数组）。

### Step 6 — Q6: 输入与上下文

- Prompt: "运行这个 skill 时，Claude 需要从用户那拿到什么？需要读哪些文件 / 项目结构？"
- 存为 `<inputs>`。

### Step 7 — Q7: 输出与产物

- Prompt: "skill 跑完会产出什么？写到哪里？"
- 存为 `<outputs>`。

### Step 8 — Q8: 外部工具 / 命令（可选）

- Prompt: "skill 内部会调用哪些命令或外部工具？（如 `xcodebuild`、`gh`、`sips`，可填『无』）"
- 存为 `<tools>`。

### Step 9 — Q9: 1–2 个使用示例（可选）

- Prompt: "给 1–2 个简短的使用示例（一行一个）。可填『暂无』。"
- 存为 `<examples>`。

## 生成的 SKILL.md 模板（10 节，对齐 ios-store-assets）

9 题访谈完成后，用 `Write` 把以下模板渲染到 `<target_path>`。`## 工作流程`、`## 反模式` 由 LLM 根据 Q6/Q7/Q8 综合写出，**不要照搬用户原话**。

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
- <反触发场景 1：基于 Q6/Q7 推断>
- <反触发场景 2>
- 用户已经知道答案、不需要本 skill 的结构化流程
- （≥2 条）

## 依赖 / 工具
<tools>（若 Q8 = "无"，写"无外部依赖；纯 Claude 工具调用即可。"）

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

**重要**：先做版本 bump，再写 SKILL.md 与 README。理由：bump 失败时整个仓库未触动；后续写文件失败时只需 `rm -rf <plugin_dir>/skills/<name>/` 加 `git checkout README.md` 即可全回滚。

### Mutation 1 — 目标 plugin 的两站点 version bump（minor +1）

```bash
cd "<repo>" || { echo "FATAL: 工作仓库 <repo> 不存在" >&2; exit 1; }
PLUGIN="<plugin>"                 # 如 sharker-ios
PLUGIN_DIR=$(jq -r --arg n "$PLUGIN" '.plugins[]|select(.name==$n).source' .claude-plugin/marketplace.json)
CURRENT=$(jq -r .version "$PLUGIN_DIR/.claude-plugin/plugin.json")
NEW=$(echo "$CURRENT" | awk -F. '{printf "%d.%d.%d", $1, $2+1, 0}')
echo "$PLUGIN: $CURRENT -> $NEW"

# Stage to /tmp（站点 1：plugin.json；站点 2：marketplace.json 中匹配 name 的条目）
jq --arg v "$NEW" '.version=$v' "$PLUGIN_DIR/.claude-plugin/plugin.json" > /tmp/plugin.json.new
jq --arg n "$PLUGIN" --arg v "$NEW" '(.plugins[]|select(.name==$n).version)=$v' .claude-plugin/marketplace.json > /tmp/marketplace.json.new

# Validate parse
jq empty /tmp/plugin.json.new && jq empty /tmp/marketplace.json.new || {
  echo "STAGE FAIL: 临时文件 jq 解析失败，已中止；未触动原文件。"
  rm -f /tmp/plugin.json.new /tmp/marketplace.json.new
  exit 1
}

# Atomic move
mv /tmp/plugin.json.new "$PLUGIN_DIR/.claude-plugin/plugin.json"
mv /tmp/marketplace.json.new .claude-plugin/marketplace.json

# Post-write verify（两站点一致）
[ "$(jq -r .version "$PLUGIN_DIR/.claude-plugin/plugin.json")" = "$NEW" ] && \
[ "$(jq -r --arg n "$PLUGIN" '.plugins[]|select(.name==$n).version' .claude-plugin/marketplace.json)" = "$NEW" ] || {
  echo "POST-WRITE MISMATCH: $PLUGIN 两站点版本不一致。"
  echo "请手动回滚（本 skill 不自动执行 git）：git checkout .claude-plugin/marketplace.json $PLUGIN_DIR/.claude-plugin/plugin.json"
  exit 1
}
echo "version OK: $PLUGIN $NEW (2 sites)"
```

### Mutation 2 — 写新 skill SKILL.md

`mkdir -p <target_path>` 的父目录后用 `Write` 写完整 10 节模板。

### Mutation 3 — 在 README 对应 plugin 小节的表格追加一行

README "Skill 目录" 按 plugin 分小节，每个表格末尾有一个锚点注释 `<!-- skills:<plugin> -->`（如 `<!-- skills:sharker-ios -->`）。

**Idempotency 守卫**先跑：

```bash
grep -q "skills/<name>/SKILL.md" README.md && { echo "README 已含 <name>，跳过追加"; SKIP_README=1; }
```

未跳过时，**清洗 description**（避免破坏表格）：
- strip newlines（替换为空格）
- escape `|` 为 `\|`
- 截断到 ≤120 字符（超出加 `…`）

得到 `<safe_description>` 后用 `Edit`（把新行插到锚点注释**之前**，锚点保持在表格末尾，保证下次仍可定位）：
- `old_string` = `<!-- skills:<plugin> -->`（目标 plugin 的锚点注释，全文唯一）
- `new_string` =
  ```
  | [<name>](./<plugin_dir 去掉前导 ./>/skills/<name>/SKILL.md) | <safe_description> |
  <!-- skills:<plugin> -->
  ```
- 链接相对 README（仓库根），形如 `./plugins/ios/skills/<name>/SKILL.md`；确保 `<plugin_dir>` 前导 `./` 已规整，不要出现 `.//`。

## Validation（提交给用户前必跑）

### Inline — 目标 plugin 两站点版本一致

```bash
PLUGIN="<plugin>"
PLUGIN_DIR=$(jq -r --arg n "$PLUGIN" '.plugins[]|select(.name==$n).source' .claude-plugin/marketplace.json)
[ "$(jq -r .version "$PLUGIN_DIR/.claude-plugin/plugin.json")" = \
  "$(jq -r --arg n "$PLUGIN" '.plugins[]|select(.name==$n).version' .claude-plugin/marketplace.json)" ] && \
echo "OK: $PLUGIN 两站点版本一致 = $(jq -r .version "$PLUGIN_DIR/.claude-plugin/plugin.json")"
```

失败 → 提示 `git checkout .claude-plugin/marketplace.json "$PLUGIN_DIR/.claude-plugin/plugin.json"` 回滚（不自动执行），停止。

### marketplace 全量 sanity（建议）

```bash
jq empty .claude-plugin/marketplace.json && \
for s in $(jq -r '.plugins[].source' .claude-plugin/marketplace.json); do
  jq empty "$s/.claude-plugin/plugin.json" || echo "FAIL: $s/.claude-plugin/plugin.json"
  [ -d "$s/skills" ] || echo "FAIL: $s/skills missing"
done
```

### 新 skill frontmatter sanity

```bash
head -5 "<target_path>" | grep -E "^name: <name>$" && \
head -5 "<target_path>" | grep -E "^description: "
```

## 完成后给用户的 Next-Step 提示

```
新 skill `<name>` 已生成：
  • <target_path>
  • plugin `<plugin>` 版本 <CURRENT> → <NEW>（2 站点已校验）
  • README "<plugin>" 小节已追加一行

请手动完成下列动作（本 skill 不替你做）：

1. 跑 Validation 三段校验
2. 在干净 Claude Code 会话 smoke test：
     /plugin marketplace add /path/to/SharkerSkills  # 或 AkaShark/SharkerSkills 公网版
     /plugin install <plugin>@sharker-skills
     /reload-plugins
     # 验证 /<plugin>:<name> 可加载
3. 提交并推送：
     git add <plugin_dir>/skills/<name> .claude-plugin/marketplace.json <plugin_dir>/.claude-plugin/plugin.json README.md
     git commit -m "feat(<name>): add <name> skill to <plugin>, bump <plugin> to v<NEW>"
     git push
```

## 反模式

- ❌ 用 `sed` 改 JSON（脆弱、易破坏格式）—— 始终用 `jq` + temp file + atomic mv
- ❌ 在 9 题访谈未走完前就开始写文件 —— 必须**先 bump version 再写 skill 文件**
- ❌ bump 时改 marketplace 顶层 `.version` 或别的 plugin 条目 —— 只动 `select(.name==<plugin>)` 命中的那一条 + 对应 plugin.json
- ❌ 自动 `git checkout` 或 `git commit` —— 本 skill 永远不动 git，只**打印**回滚命令
- ❌ 直接把用户原话灌入生成模板的 `## 工作流程` —— 必须由 LLM 结构化为编号步骤 + Acceptance
- ❌ 跳过**跨 plugin** case-insensitive 碰撞检测 —— skill 名需全仓唯一，且 macOS 默认 case-insensitive 会静默覆盖
- ❌ 把根目录当 plugin（找根 `plugin.json`）—— 多 plugin 模型下根只有 `marketplace.json`，plugin.json 在 `plugins/*/.claude-plugin/`
- ❌ 往不存在的 plugin 写 skill / 顺手新建 plugin —— 只往现有 plugin 加；新建 plugin 引导用户手动 scaffold
- ❌ 写入 Claude Code marketplace 缓存目录（`~/.claude/plugins/marketplaces/...`）—— 那是 Claude 自己维护的副本，写进去既不会进 git，也会被下次 `marketplace update` 抹掉。永远写到用户的工作 git 仓库。

## 失败模式 & 拒绝清单

| 场景 | 行为 |
|---|---|
| 名称非 kebab-case | 重 Q1，前缀 `[校验失败：…]` |
| 某 plugin `skills/<name>/` 已存在（跨 plugin, case-insensitive） | 重 Q1，前缀 `[校验失败：目录已存在]` |
| Q3 选了不存在的 plugin | 重 Q3，前缀 `[校验失败：plugin 不存在]` |
| 用户想新建 plugin 分类 | 拒绝并引导："本 skill 只往现有 plugin 加 skill；新建 plugin 请手动建目录 + plugin.json + marketplace.json `plugins[]` 条目。" |
| cwd 不含 `marketplace.json` | 拒绝并退出 |
| cwd 在 `~/.claude/plugins/` 或 `${CLAUDE_CONFIG_DIR}/plugins/` 之下（marketplace 缓存） | 拒绝并退出："禁止写入 Claude Code 缓存；请 `cd` 到工作 git 仓库后重试。" |
| 工作仓库不是 git 仓库（`git rev-parse --is-inside-work-tree` 失败） | 拒绝并退出 |
| STAGE FAIL（临时文件 jq 解析失败） | 中止；原文件未触动 |
| POST-WRITE MISMATCH | 中止；**打印** `git checkout` 对应两站点（不自动执行） |
| 用户要 git commit / push | 拒绝："本 skill 不做 git 操作；请手动跑 next-step 三条命令。" |
| 用户要多文件 skill | 拒绝："当前版本只支持单文件 SKILL.md。" |
| 用户要改用户全局 skills 目录 | 拒绝："本 skill 只动 marketplace 内 `plugins/*/skills/`。" |
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
  Q3: 归到哪个 plugin？sharker-common / sharker-ios / sharker-tool
  → 用户选：sharker-ios ✓
  （共 9 题）
  → 写 plugins/ios/skills/swift-snapshot-tester/SKILL.md
  → bump sharker-ios 0.1.0 → 0.2.0（plugin.json + marketplace 条目，2 站点）
  → README "sharker-ios" 小节追加新行
  → 给出 commit/push 提示
```

## 设计自洽性（meta-note）

本 SKILL.md 自身就是用本 skill 生成出的形态——10 节结构、9 题访谈、frontmatter、依赖、工作流、反模式、拒绝清单——可作为新 skill 的参考样本。本 skill 自己住在 `sharker-common` plugin 里（`plugins/common/skills/skill-creator/`）。
