# Deep Interview Spec: SharkerSkills Plugin

## Metadata
- Interview ID: sharker-skills-plugin
- Rounds: 4
- Final Ambiguity Score: 11%
- Type: greenfield
- Generated: 2026-05-05
- Threshold: 20%
- Status: PASSED

## Clarity Breakdown
| Dimension | Score | Weight | Weighted |
|---|---|---|---|
| Goal Clarity | 0.95 | 0.40 | 0.38 |
| Constraint Clarity | 0.85 | 0.30 | 0.255 |
| Success Criteria | 0.85 | 0.30 | 0.255 |
| **Total Clarity** | | | **0.89** |
| **Ambiguity** | | | **0.11** |

## Goal
构建一个名为 `sharker-skills` 的 Claude Code 原生 plugin，托管在 GitHub 仓库 `SharkerSkills` 上作为自建 marketplace，把作者日常使用的 skills（起步 `ios-store-assets`，后续陆续加入自创和第三方 skills）打包分发；任何人通过 `/plugin marketplace add <github-url>` + `/plugin install sharker-skills` 两行命令完成全套安装。

## Constraints
- 单 marketplace + 单 plugin 结构；新增 skill 只在 `skills/<name>/` 下加文件，不修改顶层 manifest
- 使用 Claude Code 官方 plugin 协议：`.claude-plugin/marketplace.json` + `.claude-plugin/plugin.json`
- 顶层 license：MIT
- 第三方 skill 必须在其目录内保留原 LICENSE 与 ATTRIBUTION
- 不依赖 npm/Node 安装链路；纯文件分发
- 工作目录：`/Users/sharker/Desktop/Project/Person/AI/Tool/SharkerSkills/`（当前空仓，需 `git init`）

## Non-Goals
- 不打包 `kuaishou-sso-login`（含公司内部信息，开源场景排除）
- 暂不提交到 anthropics 官方 marketplace（自建 GitHub repo 即可，未来再考虑）
- 不提供 npm CLI、安装脚本或自动化更新机制

## Acceptance Criteria
- [ ] 仓库初始化为 git repo，根目录有 `LICENSE`(MIT)、`README.md`、`.claude-plugin/marketplace.json`、`.claude-plugin/plugin.json`
- [ ] `skills/ios-store-assets/SKILL.md` 存在且与 `~/.claude/skills/ios-store-assets/` 内容一致（迁入 plugin）
- [ ] 在另一目录执行 `/plugin marketplace add <local-path-or-github-url>` 可成功加载 marketplace
- [ ] `/plugin install sharker-skills` 安装后，`/reload-plugins` 能识别到 `ios-store-assets` skill
- [ ] README 中给出两行安装命令、skill 列表、贡献指南、license 声明
- [ ] 后续新增 skill 的步骤在 README/CONTRIBUTING 中明确：`mkdir skills/<name>` + 写 `SKILL.md` + 提交

## Assumptions Exposed & Resolved
| Assumption | Challenge | Resolution |
|---|---|---|
| "plugin"形态模糊 | 列出原生 plugin / git repo / npm 包三选一 | Claude Code 原生 plugin |
| 包含哪些 skill | 列出 4 种范围 | 起步 ios-store-assets + 框架支持后续扩展 |
| 分发渠道 | 官方 marketplace vs 自建 GitHub | 自建 GitHub marketplace |
| 仓库结构 | 单 plugin vs 多 plugin | 单 plugin、skills/ 下多 skill |

## Technical Context
- Claude Code plugin 规范：`.claude-plugin/marketplace.json` 描述 marketplace（含一组 plugin entries），`.claude-plugin/plugin.json` 描述 plugin 元数据
- Skills 自动发现路径：plugin 根目录的 `skills/<name>/SKILL.md`
- 用户当前 `~/.claude/skills/ios-store-assets/` 已存在，可直接复制其内容到新 repo

## Ontology (Key Entities)
| Entity | Type | Fields | Relationships |
|---|---|---|---|
| Marketplace | core domain | name, owner, plugins[] | contains Plugin |
| Plugin | core domain | name, version, skills[], license | belongs to Marketplace, contains Skill |
| OwnSkill | core domain | name, SKILL.md, scripts | belongs to Plugin |
| ThirdPartySkill | supporting | name, SKILL.md, original LICENSE | belongs to Plugin (with attribution) |

## Ontology Convergence
| Round | Entity Count | New | Changed | Stable | Stability Ratio |
|---|---|---|---|---|---|
| 1 | 2 | 2 | - | - | N/A |
| 2 | 3 | 1 | 0 | 2 | 67% |
| 3 | 4 | 1 | 0 | 3 | 75% |
| 4 | 4 | 0 | 0 | 4 | 100% |

## Interview Transcript
<details>
<summary>Full Q&A (4 rounds)</summary>

### Round 1
**Q:** plugin 形态？
**A:** Claude Code 原生 plugin
**Ambiguity:** 58%

### Round 2
**Q:** 打包哪些 skills？
**A:** 目前只有 ios-store-assets，后续会创建别的，也可能添加别人写的
**Ambiguity:** 44%

### Round 3
**Q:** 别人安装路径？
**A:** GitHub repo + /plugin marketplace add + /plugin install
**Ambiguity:** 25%

### Round 4
**Q:** 仓库结构？
**A:** 让我决定 → 单 marketplace + 单 plugin + skills/ 多 skill + MIT
**Ambiguity:** 11%
</details>
