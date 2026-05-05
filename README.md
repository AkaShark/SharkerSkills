# SharkerSkills

Sharker 个人精选的 Claude Code skills 集合 —— 一次性装齐日常顺手的工具。

## Install

```
/plugin marketplace add AkaShark/SharkerSkills
/plugin install sharker-skills@sharker-skills
```

> 上述命令前提：GitHub 仓库已存在于 https://github.com/AkaShark/SharkerSkills 。仓库创建与 push 是部署步骤，独立完成。

## Skill 目录

| Skill | 用途 |
|---|---|
| [`ios-store-assets`](./skills/ios-store-assets/SKILL.md) | 为 iOS 项目批量生成 App Store 上架资源（App Icon / 商店截图 / Preview Poster），通过 codex CLI 调用 gpt-image-2 出图。 |

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

当前 `0.1.0` —— 1.0.0 之前可能有破坏性调整。

## License

MIT — 顶层代码与未注明原作的 skill 适用 MIT。子目录如保留有原始 LICENSE，则以子目录 LICENSE 为准。
