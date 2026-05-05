---
name: picgo-upload
description: 把本地图片通过 PicGo 桌面端上传到图床并返回 URL。本 skill 内置 bash 脚本 picgo-agent、无需全局安装。当用户生成了图片需要一条可分享链接时使用——例如生成截图、icon、AI 生图、流程图、调试截屏后想贴进 Markdown 或对外发出去。底层调用本 skill 的 scripts/picgo-agent，stdout 干净只输出 URL，便于 Agent 直接 $() 取回结果。
---

# picgo-upload

把任意本地图片通过本机 PicGo 桌面端上传到用户已配置的图床（OSS / 七牛 / S3 / 腾讯云 / GitHub / SM.MS / imgur 等），立刻拿到一条公网可访问 URL。bash 脚本随 skill 一起分发，**不需要**用户额外安装。

## 何时使用

- 「把这张图传上图床」
- 「帮我传图床」
- 「生成完截图后给个可分享链接」
- 「上传到 OSS」
- 「PicGo 那个上传怎么调」
- 「upload to image host」

## 何时不使用

- 用户没装 PicGo 桌面端 / 没开 PicGo Server / 没配置任何图床——先指引用户在 PicGo 设置里完成这些前置
- 用户要往**自己写的私有上传 API**（不是 PicGo 体系）发图——直接 `curl` 即可，不必走本 skill
- 用户要**批量**上一整个目录——v1 不支持，需要 shell 循环手动并发
- 输入是 base64 / 远程 URL / 内存 buffer——v1 只接受本地文件路径，先落盘再调
- 用户已经知道怎么调 picgo-agent 命令、只想直接执行——直接代他敲即可，不用走 skill 的回执模板

## 依赖 / 工具

- **本 skill 自带 `scripts/picgo-agent`**（bash 3.2 兼容，单文件）—— 由 Claude Code 在加载 skill 时一并落到 plugin cache 目录，无需全局安装。
- **`curl`** —— macOS / Linux 默认自带。
- **PicGo 桌面端运行中**，且 PicGo Server 已开启（默认 `127.0.0.1:36677`），且至少一个图床已配置完成。这是用户机器侧前置，本 skill 不替用户安装 PicGo。

## 输入

- **`<path>`（必需）**：本地图片文件的路径，绝对或相对都行。
  - 不允许包含 `"`、`\` 或控制字符（脚本会拒绝并报错）。
  - 如果图还在远程 URL / 内存 / base64，先 `curl -o` 或 `Write` 落到 `tmp/` 下再传。
- **`PICGO_URL`（可选，环境变量）**：覆盖默认上传端点 `http://127.0.0.1:36677/upload`，用于自定义端口或远程 PicGo。
- **`PICGO_USE_JQ=1`（可选，环境变量）**：用户机器装了 `jq` 时启用 jq 解析（更鲁棒），未装会自动回退 sed。

## 输出

- **stdout**：成功时仅一行 URL（含尾部 `\n`），失败时 0 字节。
- **stderr**：失败时一行人类可读错误信息；成功时为空。
- **exit code**：成功 `0`，业务/网络错误 `1`，用法错误 `2`。
- **副作用**：无文件落盘、无日志、无配置改动。

## 工作流程

> Claude 加载本 skill 时会得到一个「Base directory」路径（形如 `~/.claude/plugins/cache/sharker-skills/sharker-skills/<version>/skills/picgo-upload`）。**下文用 `$SKILL_DIR` 指代该路径**；实际执行时把它替换成完整路径，bash 中可写成 `SKILL_DIR=<base_dir>` 后续复用。

### Step 1 — 前置探测（不要省）

```bash
SCRIPT="$SKILL_DIR/scripts/picgo-agent"
[ -x "$SCRIPT" ] || { echo "skill bundled script missing: $SCRIPT" >&2; exit 1; }
nc -z 127.0.0.1 36677 2>/dev/null || \
  curl -fsS -m 2 -X POST -d '{}' http://127.0.0.1:36677/upload -o /dev/null 2>/dev/null
```

如果 PicGo 没监听 `36677`，**不要尝试上传**，直接告诉用户：「PicGo 桌面端没在跑（或 Server 未开启）。请打开 PicGo → 设置 → PicGo Server → 启动 Server，然后再来一次。」

**Acceptance**：脚本可执行 + PicGo Server 端口可连。两条都满足才进 Step 2。

### Step 2 — 准备图片

确认 `<path>` 是本地存在的文件：

- 相对路径直接传，脚本内部会用 `pwd -P` 解析为物理绝对路径。
- 如果原图含 `"` 或 `\`，先 `cp` 到一个安全文件名再传（脚本会拒绝危险字符）。
- 如果原图在 URL/base64/内存，先落到 `tmp/`。

**Acceptance**：`[ -r "$path" ]` 通过，且文件名不含 `"`/`\`/控制字符。

### Step 3 — 调用脚本拿 URL

```bash
URL=$("$SCRIPT" upload "$path") || {
  # stderr 已被脚本写出，原样转给用户即可
  exit 1
}
```

需要远程 PicGo / 自定义端口时改写为：

```bash
URL=$(PICGO_URL="http://192.168.1.10:36677/upload" "$SCRIPT" upload "$path")
```

**Acceptance**：`exit_code == 0` 且 `[ -n "$URL" ]`。任何一个不满足就走 Step 4 的错误回执；**不要**自动重试，**不要**捏造 URL。

### Step 4 — 给用户回执

成功：

```markdown
✅ 已上传：
<URL>

Markdown 内联：
![](<URL>)
```

失败：把 stderr 第一行原样复述，附一句「具体配置请到 PicGo 设置 / 图床后台核对」。不要自己改写错误文案。

**Acceptance**：用户能直接复制 URL 或 Markdown；不复述本地路径、不输出 shell 命令、不展示中间状态。

## 反模式

- ❌ 自己拼 `curl http://127.0.0.1:36677/upload` 调用——直接用 `$SKILL_DIR/scripts/picgo-agent`，脚本已替你处理路径解析、JSON 转义、错误判断、locale 等坑
- ❌ 把 PicGo 返回的 URL 截短 / 改写 / 加水印——它就是真理，原样回给用户
- ❌ 失败时自动重试——PicGo 失败几乎都是配置问题，重试只会刷错误日志，让用户决定
- ❌ 把 `PICGO_URL` 默认指向远程——本工具是本地接入，远程端点会泄露绝对路径给攻击者
- ❌ 跳过 Step 1 的 PicGo Server 端口探测——直接上传失败再告诉用户体验差
- ❌ 把脚本 `cp` 到 `~/.local/bin` 或其它全局位置——本 skill 设计就是「随 plugin 分发，无需安装」，bundle 的脚本是权威拷贝

## 示例

**示例 1（happy path）**

```
用户：把这张截图传一下，给我个链接
Claude（本 skill）：
  [Step 1] 探测：脚本可执行 ✓，PicGo Server 在 36677 ✓
  [Step 3] 执行：URL=$($SKILL_DIR/scripts/picgo-agent upload ./shot.png)
  [Step 4] 回执：
    ✅ 已上传：
    https://sharkerhub.oss-cn-beijing.aliyuncs.com/Obsidian/shot.png

    Markdown 内联：
    ![](https://sharkerhub.oss-cn-beijing.aliyuncs.com/Obsidian/shot.png)
```

**示例 2（PicGo 没开）**

```
用户：传这张图
Claude（本 skill）：
  [Step 1] 探测：脚本 ✓；端口 36677 不可连 ✗
  回执：PicGo 桌面端没在跑（或 Server 未开启）。
       请打开 PicGo → 设置 → PicGo Server → 启动 Server，然后再来一次。
       （不发起上传，避免无效错误日志）
```
