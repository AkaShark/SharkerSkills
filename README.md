# SharkerSkills

Sharker 个人精选的 Claude Code skills 集合 —— 一次性装齐日常顺手的工具。

## Install (Claude Code)

```
/plugin marketplace add AkaShark/SharkerSkills
/plugin install sharker-skills@sharker-skills
/reload-plugins
```

只执行 `marketplace add` 仅把市场注册到 `~/.claude/plugins/known_marketplaces.json`，**不会**真正启用任何 skill；必须再 `install` 一次。安装完成后 `/reload-plugins` 让本会话立即生效。

### 解析逻辑

- `owner/repo` 形式默认按 GitHub 解析，等价于 `https://github.com/AkaShark/SharkerSkills`
- Claude Code 拉取仓库后读取 `.claude-plugin/marketplace.json`，按其中的 `plugins[]` 注册可安装条目
- 也支持 `https://...git`、本地路径、`owner/repo@branch` 等源

## Codex 用户怎么办

**Codex CLI 不支持** Claude Code 的 plugin / marketplace / Skill 体系——`.claude-plugin/*.json`、SKILL frontmatter、hooks、agents 都是 Claude Code 专属抽象。本仓库定位是 **Claude Code 专用 skill 集合**，不为 Codex 做适配。

如果你用 Codex 想复用这里的 prompt，可以手动把 `skills/<name>/SKILL.md` 的正文作为 prompt 直接喂给 `codex`：

```
codex -p "$(cat skills/ios-store-assets/SKILL.md)"
```

注意：`ios-store-assets` 内部本身就调用 `codex` CLI 来生成图片——它的 **消费者** 是 Claude Code，**执行器** 才是 Codex；两者职责不冲突。

## Skill 目录

| Skill | 用途 |
|---|---|
| [`ios-store-assets`](./skills/ios-store-assets/SKILL.md) | 为 iOS 项目批量生成 App Store 上架资源（App Icon / 商店截图 / Preview Poster），通过 codex CLI 调用 gpt-image-2 出图。 |
| [`skill-creator`](./skills/skill-creator/SKILL.md) | 在 SharkerSkills plugin 内交互式创建新 skill —— 8 轮问答 → 生成 SKILL.md → 自动 minor-bump 三站点版本与更新 README 目录。 |
| [`picgo-upload`](./skills/picgo-upload/SKILL.md) | 把本地图片通过 PicGo 桌面端上传到图床并返回 URL；内置 bash 脚本随 plugin 分发，无需全局安装。 |

## 添加新 skill

1. `mkdir skills/<name>`
2. 在该目录创建 `SKILL.md`，文件头加 frontmatter：
   ```
   ---
   name: <name>
   description: <一句话触发描述>
   ---
   ```
3. 编写 skill 正文。
4. `.claude-plugin/marketplace.json`、`.claude-plugin/plugin.json` 同步 bump `version`。
5. 在 README "Skill 目录" 中追加一行。
6. 提交 PR。

第三方 skill 加入时，请把原作者的 `LICENSE` 与 `ATTRIBUTION` 一并放入 `skills/<name>/`。

## 版本

当前 `0.3.0` —— 1.0.0 之前可能有破坏性调整。

## License

MIT — 顶层代码与未注明原作的 skill 适用 MIT。子目录如保留有原始 LICENSE，则以子目录 LICENSE 为准。
