# Deep Interview Spec: skill-creator

## Metadata
- Interview ID: skill-creator
- Rounds: 4
- Final Ambiguity: 9%
- Type: brownfield (target = existing SharkerSkills plugin repo)
- Generated: 2026-05-05
- Threshold: 20%
- Status: PASSED

## Clarity Breakdown
| Dimension | Score | Weight | Weighted |
|---|---|---|---|
| Goal | 0.95 | 0.35 | 0.333 |
| Constraints | 0.90 | 0.25 | 0.225 |
| Success Criteria | 0.85 | 0.25 | 0.213 |
| Context | 0.95 | 0.15 | 0.143 |
| **Total** | | | **0.913** |
| **Ambiguity** | | | **0.087** |

## Goal
在 SharkerSkills plugin 内部新增一个名为 `skill-creator` 的 meta-skill。当用户触发该 skill 时，它通过多轮交互问题收集新 skill 的定义（名称、触发描述、输入、输出、依赖工具、示例），由 LLM 生成完整的 SKILL.md，写入用户指定的目录（默认 `/Users/sharker/Desktop/Project/Person/AI/Tool/SharkerSkills/skills/<new-name>/SKILL.md`），并自动同步更新 plugin 的 `marketplace.json`、`plugin.json` 三处 `version` 字段（patch bump）以及 `README.md` 的 Skill 目录表。**不**自动 git commit、**不**自动 git push。

## Constraints
- Meta-skill 自身路径：`SharkerSkills/skills/skill-creator/SKILL.md`，作为 sharker-skills plugin 的一部分发布
- 默认输出目录：`/Users/sharker/Desktop/Project/Person/AI/Tool/SharkerSkills/skills/`，用户可在 skill 触发时改写
- 新 skill 命名校验：必须 kebab-case，正则 `^[a-z][a-z0-9-]*$`
- frontmatter 必填：`name`、`description`
- 不修改 `~/.claude/skills/` 下任何文件
- 不自动 git 操作（commit/push 由用户决定）
- 不覆盖已存在的 skill 目录（若 `skills/<name>/` 已存在则报错并退出）

## Non-Goals
- 不做 git commit、push、PR 创建
- 不向 anthropics 官方 marketplace 提交
- 不验证 SKILL.md 在 Claude Code runtime 的可加载性（用户自己手动 smoke test）
- 不支持生成多文件 skill（脚本、refs、assets 等子目录）首版只生成单文件 SKILL.md
- 不内置第三方 skill 引入流程（带 LICENSE 复制）

## Acceptance Criteria
- [ ] `SharkerSkills/skills/skill-creator/SKILL.md` 存在，frontmatter 包含 `name: skill-creator` 和清晰的触发描述
- [ ] skill 触发时按顺序问以下 8 个问题（可由 AskUserQuestion 实现）：
  1. 新 skill 的 kebab-case 名称
  2. 触发场景描述（一句话，会进 frontmatter description）
  3. 输出目录确认（默认 `SharkerSkills/skills/`）
  4. 何时使用（多个触发短语）
  5. 输入与上下文（用户提供什么、是否需要读文件）
  6. 输出与产物（生成什么、写到哪里）
  7. 使用的外部工具/命令（可选）
  8. 1-2 个使用示例（可选）
- [ ] 命名校验失败时给出错误消息并允许重试
- [ ] 目标目录已存在 `skills/<name>/` 时拒绝执行并提示用户
- [ ] 生成的 SKILL.md 至少包含：frontmatter（name+description）、`# 标题`、`## 何时使用`、`## 工作流程`、`## 输入`、`## 输出`、`## 示例`
- [ ] 自动 bump 三处 version：`marketplace.json` root `version`、`marketplace.json` `plugins[0].version`、`plugin.json` `version`（patch +1）
- [ ] 自动追加 README "Skill 目录" 表格新行：`| [\`<name>\`](./skills/<name>/SKILL.md) | <description> |`
- [ ] 对 SharkerSkills plugin 自身 patch-bump（首次发布时把 sharker-skills 自己的版本也带到包含 skill-creator 的版本）
- [ ] 完成后给用户清晰的 next-step 提示：跑 14 行验收 + 手动 commit + push

## Assumptions Exposed & Resolved
| Assumption | Challenge | Resolution |
|---|---|---|
| 作用边界 | 只生成文件 vs 全流程 push | 生成 + 更 manifest/README，**不** commit/push |
| 输出目录 | 硬编码 vs 参数化 | 默认 SharkerSkills/skills/，可交互改写 |
| 正文产出 | 模板 vs LLM 生成 | 多轮交互 + LLM 生成完整正文 |
| meta-skill 位置 | plugin 内 vs ~/.claude/skills | 放在 SharkerSkills/skills/skill-creator/ |

## Technical Context
- SharkerSkills plugin 已 push 到 github.com/AkaShark/SharkerSkills
- 当前版本 0.1.0；本次发布 skill-creator 时 bump 到 0.2.0
- Plugin manifest 校验脚本就是已有 14 行 jq 验收（在 `.omc/plans/sharker-skills-bootstrap.md`）

## Ontology (Key Entities)
| Entity | Type | Fields | Relationships |
|---|---|---|---|
| MetaSkill (skill-creator) | core | name, SKILL.md, interaction-flow | belongs to PluginManifest |
| GeneratedSkill | core | name, description, body | created by MetaSkill, written to TargetDir |
| TargetDir | supporting | path (default SharkerSkills/skills/) | hosts GeneratedSkill |
| PluginManifest | supporting | marketplace.json, plugin.json, README.md | updated by MetaSkill on each generation |

## Ontology Convergence
| Round | Count | New | Stable | Stability |
|---|---|---|---|---|
| 1 | 3 | 3 | - | N/A |
| 2 | 4 | 1 | 3 | 75% |
| 3 | 4 | 0 | 4 | 100% |
| 4 | 4 | 0 | 4 | 100% |

## Interview Transcript
<details><summary>4 rounds</summary>

R1 Q: 作用边界？ A: 生成 + 更新 manifest/README（不 commit/push）
R2 Q: 输出目录怎么定？ A: 默认 SharkerSkills/skills/，可交互改写
R3 Q: 正文怎么产出？ A: 多轮交互 + LLM 生成
R4 Q: meta-skill 自身放哪？ A: SharkerSkills/skills/skill-creator/SKILL.md
</details>
