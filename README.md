# SharkerSkills

Sharker 个人精选的 Claude Code skills 集合 —— 按用途拆成 **4 个分类 plugin**，项目里需要哪类就装哪类。其中 `sharker-sdd` 不是离散工具，而是一整套 **Spec-Driven Development 流水线 + 自生长工程知识库**。

## Install (Claude Code)

先把 marketplace 注册一次，再按需安装其中的分类 plugin：

```
/plugin marketplace add AkaShark/SharkerSkills
/plugin install sharker-sdd@sharker-skills      # SDD 流水线 + 自生长工程知识库
/plugin install sharker-ios@sharker-skills      # iOS / App Store 资源
/plugin install sharker-tool@sharker-skills     # 独立工具（图床上传等）
/plugin install sharker-common@sharker-skills   # 通用 / meta（含 skill-creator）
/reload-plugins
```

- `marketplace add` 只把市场注册到 `~/.claude/plugins/known_marketplaces.json`，**不会**真正启用任何 skill；必须再对每个想用的分类 plugin `install` 一次。
- 各 plugin 互相独立，只装你需要的那几个即可。
- 安装完成后 `/reload-plugins` 让本会话立即生效。
- skill 安装后以**命名空间**形式调用：`/sharker-ios:ios-store-assets`、`/sharker-tool:picgo-upload` 等（自动触发仍按各 skill 的 `description`，不受命名空间影响）。

> **从旧版本升级**：0.3.x 时全部 skill 打包在单个 `sharker-skills` plugin 里。0.4.0 起已拆分，旧的 `sharker-skills@sharker-skills` 不再存在；请改装上面三个分类 plugin id。

### 解析逻辑

- `owner/repo` 形式默认按 GitHub 解析，等价于 `https://github.com/AkaShark/SharkerSkills`
- Claude Code 拉取仓库后读取 `.claude-plugin/marketplace.json`，按其中的 `plugins[]` 注册可安装条目（本仓库声明了 3 个）
- 也支持 `https://...git`、本地路径、`owner/repo@branch` 等源

## Codex 用户怎么办

**Codex CLI 不支持** Claude Code 的 plugin / marketplace / Skill 体系——`.claude-plugin/*.json`、SKILL frontmatter、hooks、agents 都是 Claude Code 专属抽象。本仓库定位是 **Claude Code 专用 skill 集合**，不为 Codex 做适配。

如果你用 Codex 想复用这里的 prompt，可以手动把 `plugins/<plugin>/skills/<name>/SKILL.md` 的正文作为 prompt 直接喂给 `codex`：

```
codex -p "$(cat plugins/ios/skills/ios-store-assets/SKILL.md)"
```

注意：`ios-store-assets` 内部本身就调用 `codex` CLI 来生成图片——它的 **消费者** 是 Claude Code，**执行器** 才是 Codex；两者职责不冲突。

## Skill 目录

### sharker-sdd — SDD 流水线 + 工程知识库

一整套 Spec-Driven Development 工作流：`sdd-init` 一次铺出 `.sdd/` 脚手架，之后按 `spec → design → tasks → impl` 推进；开发过程中产生的决策 / 踩坑 / 模式由 AI **自动沉淀**进 `knowledge/`，下次开工**自动召回**，形成复利闭环。借鉴 [cc-sdd](https://github.com/gotalab/cc-sdd) / [spec-kit](https://github.com/github/spec-kit) / [karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)，每个 skill 内透明标注借鉴点。

| Skill | 用途 |
|---|---|
| [`sdd-init`](./plugins/sdd/skills/sdd-init/SKILL.md) | 一键在当前项目铺出 `.sdd/` 脚手架（constitution / schema / 空 knowledge/ / specs/），是整条流水线的入口。 |
| [`sdd-spec`](./plugins/sdd/skills/sdd-spec/SKILL.md) | 把一句话需求结构化为 `specs/<feat>/spec.md`（目标 + EARS 验收 + 非目标）；**开头先召回知识库**避免重蹈历史坑。 |
| [`sdd-design`](./plugins/sdd/skills/sdd-design/SKILL.md) | 把 spec.md 推导为 `design.md`（架构 + 关键决策 + 取舍）；**结尾把架构决策沉淀进 `knowledge/decisions/`**。 |
| [`sdd-tasks`](./plugins/sdd/skills/sdd-tasks/SKILL.md) | 把 design.md 拆为有序 `tasks.md`，每条带依赖 / 涉及模块 / 验收标注。 |
| [`sdd-impl`](./plugins/sdd/skills/sdd-impl/SKILL.md) | 逐任务执行（复用 OMC executor + TDD + 逐任务 review）；**debug 成功沉淀进 `lessons/`、完成后更新 `modules/`**。 |
| [`kb-save`](./plugins/sdd/skills/kb-save/SKILL.md) | 手动沉淀兜底：用户说「把这个记下来」时，结构化成知识页写入对应目录并回写 `index.md`。 |
| [`kb-query`](./plugins/sdd/skills/kb-query/SKILL.md) | 召回：读 `index.md` → 按 tags/关键词定位相关页 → 只读那几页 → 综合回答并标注来源。纯 grep + 按需读，不上 embedding。 |
| [`kb-lint`](./plugins/sdd/skills/kb-lint/SKILL.md) | 防腐巡检：查矛盾 / 过时 / 孤儿页 / 缺失交叉引用 + 召回规模红线，产出报告与修复建议，不自动删。 |
<!-- skills:sharker-sdd -->

### sharker-ios — iOS / Apple

| Skill | 用途 |
|---|---|
| [`ios-store-assets`](./plugins/ios/skills/ios-store-assets/SKILL.md) | 为 iOS 项目批量生成 App Store 上架资源（App Icon / 商店截图 / Preview Poster），通过 codex CLI 调用 gpt-image-2 出图。 |
<!-- skills:sharker-ios -->

### sharker-tool — 独立工具

| Skill | 用途 |
|---|---|
| [`picgo-upload`](./plugins/tool/skills/picgo-upload/SKILL.md) | 把本地图片通过 PicGo 桌面端上传到图床并返回 URL；内置 bash 脚本随 plugin 分发，无需全局安装。 |
<!-- skills:sharker-tool -->

### sharker-common — 通用 / meta

| Skill | 用途 |
|---|---|
| [`skill-creator`](./plugins/common/skills/skill-creator/SKILL.md) | 在 SharkerSkills marketplace 内交互式创建新 skill —— 9 轮问答（含「归属哪个 plugin」）→ 生成 SKILL.md → 自动 minor-bump 目标 plugin 两站点版本与更新 README 目录。 |
| [`solo-review-branch`](./plugins/common/skills/solo-review-branch/SKILL.md) | 从混杂的功能分支里抽出「只有我自己改动」的独立 review 分支（git blame 作者过滤 + 功能路径双层隔离，自动收敛多次提交的 churn），并支持把工作分支新改动增量同步过去。 |
<!-- skills:sharker-common -->

## 添加新 skill

推荐直接用 `skill-creator`（在 `sharker-common` 里）：说「帮我加一个 skill」，它会走 9 轮问答，**包括选归属哪个 plugin**，然后生成文件、bump 目标 plugin 版本、追加 README。

手动添加流程：

1. 选好归属 plugin（`common` / `ios` / `tool`），`mkdir -p plugins/<plugin>/skills/<name>`
2. 在该目录创建 `SKILL.md`，文件头加 frontmatter：
   ```
   ---
   name: <name>
   description: <一句话触发描述>
   ---
   ```
3. 编写 skill 正文。
4. bump 该 plugin 的**两站点** `version`：`plugins/<plugin>/.claude-plugin/plugin.json` 与 `.claude-plugin/marketplace.json` 中对应 `plugins[]` 条目。
5. 在 README 对应 plugin 小节的表格里（锚点注释 `<!-- skills:<plugin> -->` 之前）追加一行。
6. 提交 PR。

> 新建一个**分类 plugin**（在 common/ios/tool 之外）需手动 scaffold：建 `plugins/<x>/.claude-plugin/plugin.json`（不带 `$schema`）与 `plugins/<x>/skills/`，并在 `marketplace.json` 的 `plugins[]` 增加一条 `source: "./plugins/<x>"`。

第三方 skill 加入时，请把原作者的 `LICENSE` 与 `ATTRIBUTION` 一并放入 `plugins/<plugin>/skills/<name>/`。

## 版本

Marketplace 目录版本 `0.5.0`（本次新增 `sharker-sdd` plugin）。各分类 plugin 独立版本：

| Plugin | 版本 |
|---|---|
| `sharker-common` | 0.2.1 |
| `sharker-ios` | 0.1.0 |
| `sharker-tool` | 0.1.0 |
| `sharker-sdd` | 0.1.0 |

1.0.0 之前可能有破坏性调整。

## License

MIT — 顶层代码与未注明原作的 skill 适用 MIT。子目录如保留有原始 LICENSE，则以子目录 LICENSE 为准。
