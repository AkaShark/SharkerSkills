#!/usr/bin/env bash
# 把本目录下的命令/agents/skills symlink 到「当前项目」的 .claude/（项目级，不再写 ~/.claude）。
# 正本留在本文件夹（git 管理），软链到 ../.claude/ —— 编辑任意一边都同步。
# 生成的软链已被 .gitignore；克隆到新机器后重跑本脚本，按本机路径重建即可。可重复执行（幂等）。
#
# 用法：
#   ./install.sh
#
# 覆盖默认目标 .claude 位置：CLAUDE_DIR=/path/to/.claude ./install.sh
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SRC_DIR/.." && pwd)"          # 本文件夹的父目录 = 项目根
CLAUDE_DIR="${CLAUDE_DIR:-$PROJECT_ROOT/.claude}"  # 项目级 .claude（不是 ~/.claude）

link_dir() {
  local sub="$1"   # commands / agents / skills ...
  [ -d "$SRC_DIR/$sub" ] || return 0
  mkdir -p "$CLAUDE_DIR/$sub"
  for f in "$SRC_DIR/$sub"/*; do
    [ -e "$f" ] || continue
    local dest="$CLAUDE_DIR/$sub/$(basename "$f")"
    ln -sfn "$f" "$dest"
    echo "  linked  $dest -> $f"
  done
}

echo "==> 安装到项目级 $CLAUDE_DIR"
link_dir commands
link_dir agents
link_dir skills
echo "==> 完成。当前项目的 Claude Code 会话即可使用这些命令（如 /hswiki）。"
echo
echo "提示：/hswiki 写入的目标目录默认是这台机器上的 vault 路径。"
echo "      若你换了机器 / vault 不在原位置，请在 shell 配置里设置一次："
echo
echo "      export HSWIKI_RAW=\"/你的/路径/LLMWiki/回森架构知识库/raw\""
echo
echo "      （写进 ~/.zshrc 后 source 一下；不设置则用命令里写死的默认路径。）"
