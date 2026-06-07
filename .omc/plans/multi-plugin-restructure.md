# Plan — SharkerSkills 拆成 3 个分类 plugin（common / ios / tool）

> 目标：把当前单一 `sharker-skills` plugin 拆成同一 marketplace 下的 3 个分类 plugin，
> 让项目按需 `/plugin install <plugin>@sharker-skills`。同时改造 `skill-creator`，
> 创建新 skill 时需选择所属 plugin，并按「单 plugin 两站点」模型 bump 版本。

## 决策（已确认）

- Plugin 命名：`sharker-common` / `sharker-ios` / `sharker-tool`（带 `sharker-` 前缀避免跨 marketplace 撞名）
- 三个新 plugin 初始版本：各自重置为 `0.1.0`
- Marketplace 顶层 `version`：作为目录版本，本次重构 bump 到 `0.4.0`，**与各 plugin 版本解耦**

## Skill → Plugin 映射

| Skill | 新 plugin | 新路径 |
|---|---|---|
| `skill-creator` | `sharker-common` | `plugins/common/skills/skill-creator/` |
| `ios-store-assets` | `sharker-ios` | `plugins/ios/skills/ios-store-assets/` |
| `picgo-upload` | `sharker-tool` | `plugins/tool/skills/picgo-upload/`（含 `scripts/picgo-agent`） |

## 目标目录结构

```
SharkerSkills/
  .claude-plugin/
    marketplace.json              # 目录：3 个 plugin 条目（删掉 plugin.json）
  plugins/
    common/.claude-plugin/plugin.json   # name: sharker-common, version 0.1.0
            skills/skill-creator/SKILL.md
    ios/.claude-plugin/plugin.json      # name: sharker-ios, version 0.1.0
            skills/ios-store-assets/SKILL.md
    tool/.claude-plugin/plugin.json     # name: sharker-tool, version 0.1.0
            skills/picgo-upload/SKILL.md + scripts/picgo-agent
  README.md  LICENSE  .gitignore  .omc/
```

根目录 `.claude-plugin/plugin.json` **删除**（根不再是 plugin，只是 marketplace）。

## 版本模型变化

- 旧：一个版本写在 **3 站点**（root plugin.json、marketplace 顶层、marketplace.plugins[0]）。
- 新：**每个 plugin 独立版本，存在于 2 站点**
  - `plugins/<x>/.claude-plugin/plugin.json` 的 `.version`
  - `marketplace.json` 中 `.plugins[] | select(.name==<plugin>) | .version`
- marketplace 顶层 `.version` 改为独立的目录版本，不再随 plugin 联动。

---

## 步骤

### Step 0 — 前置
- 新建分支 `restructure/multi-plugin`（CLAUDE.md：非平凡改动先开分支）。
- 工作区当前的 `M .omc/project-memory.json` 与未跟踪 session 文件不影响，照常。

### Step 1 — `git mv` 迁移三个 skill 目录（保留历史）
- `git mv skills/skill-creator plugins/common/skills/skill-creator`
- `git mv skills/ios-store-assets plugins/ios/skills/ios-store-assets`
- `git mv skills/picgo-upload plugins/tool/skills/picgo-upload`
- 删空的 `skills/`
- **验收**：`plugins/*/skills/*/SKILL.md` 存在；`skills/` 不存在；`git status` 显示 rename；`picgo-agent` 仍是 `-rwxr-xr-x`。

### Step 2 — 写 3 份 `plugin.json`（不带 `$schema`）
每个 `plugins/<x>/.claude-plugin/plugin.json`：`name`/`version: 0.1.0`/`description`/`author`/`repository`/`homepage`/`license: MIT`/`keywords`/`skills: "./skills/"`。
- common：meta/工具类（keywords: skills, meta, generator, productivity）
- ios：iOS/Apple（keywords: ios, app-store, assets, xcode）
- tool：独立工具（keywords: tools, image, upload, picgo）
- **验收**：`jq empty` 通过；无 `$schema` 键。

### Step 3 — 重写 `marketplace.json`
顶层保留 `$schema`/`name: sharker-skills`/`owner`，`version` → `0.4.0`；`plugins[]` 改为 3 条，每条带 `name`/`source: "./plugins/<x>"`/`version: 0.1.0`/`description`/`author`/`category: productivity`/`homepage`/`tags`。
- **验收**：`jq empty` 通过；3 条 `source` 目录均存在且各含 `.claude-plugin/plugin.json` + `skills/`。

### Step 4 — 修 picgo-upload 缓存路径文案
`plugins/tool/skills/picgo-upload/SKILL.md:50` 的示例路径第二段 `sharker-skills` → `sharker-tool`
（`~/.claude/plugins/cache/sharker-skills/sharker-tool/<version>/skills/picgo-upload`）。仅文案，加载时实际路径由 Claude Code 注入，但保持准确。

### Step 5 — 改造 `skill-creator`（核心）
文件：`plugins/common/skills/skill-creator/SKILL.md`
- **5a frontmatter**：描述里加入「创建时需指定所属 plugin」。
- **5b 前置检查**：根标记改为只认 `.claude-plugin/marketplace.json`（根 plugin.json 已不存在）；仍拒绝 cache 路径、仍要求 git work tree；plugin 列表动态读：`jq -r '.plugins[].name' .claude-plugin/marketplace.json`。
- **5c 新增一题（plugin scope）**：插入为新 Q3，总题数 8→9。选项来自上面的 jq 列表；选「Other / 新建 plugin」→ 拒绝并提示手动 scaffold。存 `<plugin>` 与 `<plugin_dir>`（`jq -r '.plugins[]|select(.name==$n).source'`）。
- **5d 输出路径**：默认 `<plugin_dir>/skills/<name>/SKILL.md`。
- **5e 撞名检测**：跨所有 plugin 扫 —— `find plugins/*/skills -maxdepth 1 -type d -iname "<name>"`（skill 名全仓唯一）。
- **5f Mutation 1 版本 bump（3 站点 → 单 plugin 2 站点）**：
  ```bash
  CURRENT=$(jq -r .version "$PLUGIN_DIR/.claude-plugin/plugin.json")
  NEW=$(echo "$CURRENT" | awk -F. '{printf "%d.%d.%d",$1,$2+1,0}')
  jq --arg v "$NEW" '.version=$v' "$PLUGIN_DIR/.claude-plugin/plugin.json" > /tmp/plugin.json.new
  jq --arg n "$PLUGIN" --arg v "$NEW" '(.plugins[]|select(.name==$n).version)=$v' \
     .claude-plugin/marketplace.json > /tmp/marketplace.json.new
  # jq empty 校验 → atomic mv → 回读断言两站点 == NEW
  ```
- **5g Mutation 3 README**：追加到对应 plugin 子表；idempotency 守卫用新路径。
- **5h 校验/next-step/反模式/失败清单**：路径全改；安装命令 → `/plugin install <plugin>@sharker-skills`；版本一致性校验改 2 站点；新增失败行（plugin scope 非法、请求新建 plugin 被拒）。
- **5i meta-note**：更新自洽性说明对应新布局。

### Step 6 — 重写 `README.md`
- 安装块：`marketplace add` 一次 + 三条 `/plugin install sharker-<x>@sharker-skills`（带注释）。
- 「Skill 目录」：按 plugin 分 3 个小节/表，路径改 `./plugins/<x>/skills/<name>/SKILL.md`。
- 修 codex 示例路径（`README.md:28`）。
- 「添加新 skill」：更新为子目录布局，并说明 skill-creator 现在会问 plugin scope。
- 「版本」：列各 plugin 0.1.0 + marketplace 0.4.0。
- **加一段破坏性变更提示**：原 `sharker-skills@sharker-skills` 已不存在，需改装 3 个新 id。

### Step 7 — `.omc/plans` 旧 bootstrap 文档
旧文档基于单 plugin + 14 行验收，标注「已由本 plan 取代」，不删。

### Step 8 — 校验（只读）
`jq empty` 全部 manifest；每个 `plugins[].source` 存在且结构完整；`plugins[].version` == 对应 plugin.json `.version`；无根 plugin.json；无 `$schema` on plugin.json；`picgo-agent` 可执行；README 无残留 `./skills/` 死链。

### Step 9 — Smoke test（用户在干净会话手动跑）
```
/plugin marketplace add /Users/sharker/Desktop/Project/Person/AI/Tool/SharkerSkills
/plugin install sharker-tool@sharker-skills
/reload-plugins
# 验证 /sharker-tool:picgo-upload 加载；其余两个同理
```

### Step 10 — 提交（分支上，approve 后）
`git add -A` → `refactor: split sharker-skills into common/ios/tool plugins`（push 需用户明确要求）。

## 风险

- **破坏性**：已装旧 plugin 的人需重装 3 个新 id（README 提示）。
- Skill 调用名变为 `/sharker-<x>:<skill>`（命名空间化）；按 description 自动触发不受影响。
- picgo 缓存路径文案为示意，即便漏改也不影响执行（加载器注入真实路径），仍修以保持准确。
