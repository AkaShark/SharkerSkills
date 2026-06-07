# claude-code-local

本项目（SharkerSkills）的**项目级** Claude Code 资产：slash command 等。正本放在这里用 git 管理，
`install.sh` 把它们 symlink 进项目根的 `.claude/`，只对**本项目**的会话生效（不再写 `~/.claude/`、不再全局）。

> 跟「用户级」（`~/.claude/`，所有项目都能用）的区别：这里是**项目级**，仅当前仓库的 Claude Code 会话能用。
> 由 `Plugin/claude-code-global/`（用户级）改造迁移而来。

## 目录

```
claude-code-local/
├── commands/          # 项目级 slash command 正本（→ ../.claude/commands/）
│   └── hswiki.md      # 把对话按话题拆分、命名，存进「回森架构知识库」的 raw/
├── install.sh         # 把 commands/（及 agents/ skills/ 若有）symlink 进 ../.claude/
└── README.md
```

## 用法

```bash
# 在本文件夹里跑一次，命令就会“发放”到当前项目的 .claude/commands/ 下
./install.sh
```

之后在**本项目**的 Claude Code 会话里输入 `/hswiki` 即可。

## 加新命令

把 `.md` 丢进 `commands/`，重跑 `./install.sh`，新命令就发放到当前项目的 `.claude/commands/`。
`install.sh` 也会处理 `agents/`、`skills/`（若存在）。

## 工作原理

- **正本在 `commands/`，软链在 `.claude/commands/`**：Claude Code 只从 `.claude/commands/` 找项目级命令；
  软链过去后，编辑任意一边都同步。
- **生成的软链不进 git**：`.claude/commands/` 已被 `.gitignore`；进 git 的是正本（本文件夹）。
  克隆到新机器后重跑 `./install.sh`，按本机路径重建软链即可。
- **`$HSWIKI_RAW`**：`hswiki.md` 的写入目录优先读环境变量 `$HSWIKI_RAW`，未设置才回退写死的默认路径。
  换机器 / vault 移位时只改这个环境变量，不用动命令文件。
