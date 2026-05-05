# Plan: skill-creator Bootstrap (sharker-skills v0.2.0)

**Status:** APPROVED via Ralplan consensus (Planner → Architect ITERATE → Planner revise → Critic ITERATE → 修正合并落地)
**Spec:** `.omc/specs/deep-interview-skill-creator.md`
**Working dir:** `/Users/sharker/Desktop/Project/Person/AI/Tool/SharkerSkills/`
**Target:** plugin 0.1.0 → 0.2.0

---

## ADR: Minor vs Patch Bump
spec 文本曾写"patch +1"（spec line 23 已统一为 8 题），但实质语义：每新增一个 skill = 新功能 = **minor +1**。本次 0.1.0 → 0.2.0 是首条遵循此约定的发布。Steady-state policy: **每新增一个 skill → minor +1，直到 1.0.0**。

## Bootstrap 执行顺序（**先 version bump，后写文件**——失败时回滚范围最小）

1. **原子三站点 version bump**: `.claude-plugin/plugin.json` `.version` + `.claude-plugin/marketplace.json` `.version` + `.claude-plugin/marketplace.json` `.plugins[0].version` 全部 0.1.0 → 0.2.0；stage 到 /tmp，`jq empty` 校验，`mv` 落地，post-write 三站点比对。失败时**仅打印** `git checkout .claude-plugin/`，不自动执行。
2. **mkdir + Write `skills/skill-creator/SKILL.md`**（详见 §SKILL.md Body 节）
3. **Edit README**: 在 ios-store-assets 行后追加 skill-creator 行（idempotent guard: 先 `grep -q "skills/skill-creator/SKILL.md" README.md`，命中则跳过）
4. **Inline Row 10**: `[ "$(jq -r .version .claude-plugin/marketplace.json)" = "0.2.0" ] && [ "$(jq -r .version .claude-plugin/plugin.json)" = "0.2.0" ] && [ "$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)" = "0.2.0" ]`
5. **完整 14 行验收**（按 sharker-skills-bootstrap.md Step 7 表格逐行）
6. **报告 + 还给用户做 commit/push**

## Generated SKILL.md 模板（10 节，对齐 ios-store-assets 质感）

未来 skill-creator 跑出的新 skill 应包含：frontmatter / # 标题+tagline / ## 何时使用 / ## 何时不使用 / ## 依赖 / ## 工作流程（带 Acceptance）/ ## 输入 / ## 输出 / ## 反模式 / ## 示例。**retry 语义**置于 ## 工作流程 总规则中，校验失败时复用同一 AskUserQuestion 并前缀 `[校验失败：…]`。

## README 追加格式
- 提取新 skill frontmatter `description`，**strip newlines**、**escape `|` 为 `\|`**、**截断 ≤120 字符**
- 行格式：`| [`<name>`](./skills/<name>/SKILL.md) | <safe-description> |`
- idempotency: 追加前 grep 是否已含目标 link

## 回滚
- 三站点 mismatch: 仅打印 `git checkout .claude-plugin/`（不自动执行，符合 spec "不自动 git 操作"）
- 部分写入失败（先 bump 后写文件的顺序保证版本已成功才会写新 skill 文件；若 SKILL.md/README 写失败，用户跑 `git checkout .claude-plugin/ README.md && rm -rf skills/<name>/` 即可全回滚）

## v0.3+ Follow-ups
1. spec 文本已修（"6 个问题"→"8 个问题"，line 43）
2. plugin description "Seeded with ios-store-assets" 待更新
3. keywords/tags 加入 `meta`/`generator`
4. README 追加从 `Edit` 锚定升级为 awk/yq 表格识别
5. 多文件 skill 支持（scripts/refs/assets）
6. `--edit <name>` 模式（覆盖既有 skill）
7. `--dry-run` 模式（先 diff）
8. version lock-step 抽 `.omc/plans/` 共享片段
