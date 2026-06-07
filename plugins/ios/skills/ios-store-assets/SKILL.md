---
name: ios-store-assets
description: 为 iOS 项目生成 App Store 上架所需的视觉资源（App Icon、商店截图、Preview Poster），通过 codex CLI 调用 gpt-image-2 生成位图。产出符合 Apple Human Interface Guidelines 的简约美观图片。当用户说"生成 iOS 图标 / 上架资源 / 商店截图 / App Store screenshot / 替换 icon / 上架素材"等意图时使用。
---

# iOS App Store 资源生成 Skill

为 iOS 项目批量产出 App Store 上架所需的视觉资源——App Icon、商店截图、App Preview Poster——并把文件按 Apple 规范交付到项目目录。

## 何时使用

- "帮我生成 iOS 上架资源 / 商店素材 / 截图"
- "做一个 App Icon / 替换图标 / icon 重做"
- "生成 App Store screenshot / preview poster"
- 用户拥有 iOS 工程，需要补齐上架前的 1024 icon 与 1290×2796 截图

## 何时不使用

- 用户只是要一个普通插画或 logo（用 `frontend-design:frontend-design` 直接处理）
- 用户要 SVG / 矢量 / 代码原生 UI（应该写 SwiftUI 或 SVG，不走位图生成）
- 已经有完整素材包，只是需要切尺寸（直接用 `sips` 即可，不必走本 skill）

## 依赖

- **`frontend-design:frontend-design`** — 用于"美学方向"决策。本 skill 在产出每条 prompt 之前必须先借鉴该 skill 的设计哲学：选定一种 BOLD 的美学方向（editorial / wax-seal / Penguin Classics / Swiss / brutalist / art-deco …），避免任何 AI-slop 配色（紫渐变、Inter 字体、对称 emoji）。
- **`codex` CLI + `image_gen`（gpt-image-2）** — 实际生图工具。本 skill 的输出 = 一段段可直接喂给 `codex exec` 的 prompt 与命令。
- **本机工具** — `sips`（验证尺寸 / 缩放 / 检查 alpha）、`file`（确认 PNG 格式）。

## 核心工作流（必须按顺序执行）

### Step 1 — 摸清项目

读取这些文件来理解 App 的功能、色彩与气质，**不要**凭空臆造：

- `*.xcodeproj` / `project.yml` / `Info.plist` —— 拿到 App 名、bundle id
- 主要 Tab / 入口 View（搜 `TabView`、`NavigationSplitView`）—— 列出功能模块
- `Assets.xcassets/AppIcon.appiconset/Contents.json` —— 现有 icon 尺寸清单
- `REQUIREMENTS.md` / `README.md` / `Agent.md` —— 产品定位、目标用户
- 已有 `Res/` 或 `Resources/` —— 现存哪些素材，分辨率是否合规

把以上压缩成 **一段 ≤ 5 行的 "Project Brief"** 给用户，作为后续 prompt 的事实底座。

### Step 2 — 选定美学方向（多轮讨论，关键步骤）

调用 `frontend-design:frontend-design` 的设计哲学，**主动给出 3 个差异化的方向**让用户选，每个方向必须包含：

1. **风格名**（editorial / wax-seal / letterpress / architectural / brutalist …）
2. **主色板**（hex 三色，主色 + 辅色 + 强调色）
3. **核心元素**（一个英雄符号，例如"巨大 Didone C + 红线"）
4. **气质一句话**（"Penguin Classics meets MUJI"）

⚠️ **禁止**：

- 给用户"我建议……"然后直接生成 —— 必须等用户确认或要求迭代
- 默认保险方案（如"clean modern minimalism"）—— 必须是有 POV 的强方向
- 复用上一个项目用过的方向 —— 每个项目都应该有独特身份

讨论可以多轮：用户可能说"第二个方向但配色换成深绿"或"再给我看几个"——继续迭代，直到用户明确说"用这个 / 就这样 / 开始生成"。

### Step 3 — 写出可生成的 Prompt 集

确定方向后，按下表为 **每个资源** 写一段独立的 prompt，全部汇总到项目内 `Res/IMAGE_PROMPTS.md`（或类似路径，跟着已有项目惯例）：

| 资源 | 尺寸（px） | Apple 规范要点 |
|---|---|---|
| App Icon | **1024 × 1024** | 不透明 RGB、**无 alpha、无圆角、无阴影**（系统会加） |
| iPhone 6.9" 截图（必交） | **1290 × 2796** | 竖屏，最少 3 张推荐 5 张 |
| iPhone 6.5" 截图（兼容老机） | 1284 × 2778 | 可选 |
| iPad 13" 截图（如支持） | 2064 × 2752 | 竖屏 |
| App Preview Poster | 1290 × 2796 | 视频封面，可选 |

每段 prompt **必须包含**：

- 明确尺寸 + "fully opaque, no rounded corners, no drop shadow, no transparency"（icon）
- 三色 hex 色板，与 Step 2 选定一致
- 单一英雄元素描述（构图、占比、对齐）
- **Negative list**：`NO Apple logo, NO Cambridge crest, NO university crest, NO copyrighted marks, NO text other than X, NO emoji, NO stock-photo aesthetics, NO purple gradient`
- 截图额外注明："UI text must be readable English/Chinese typography, not gibberish"

让用户再 review 一遍 prompt 文案，**得到第二次确认** 后再进入 Step 4。

### Step 4 — 调用 codex 生成

每张图一条命令，单独跑（便于并行 + 便于审 UI 拼写）。模板：

```bash
codex exec --dangerously-bypass-approvals-and-sandbox \
  "使用 image_gen 工具生成一张 <W>x<H> 的 PNG，最终保存到 <绝对路径>。生成后用 sips 验证尺寸与 hasAlpha=no（icon 必须 no）。Prompt: <Step 3 写好的 prompt>"
```

注意事项：

- **绝对路径**，不要用 `~` 或相对路径
- 输出目录建议 `<项目>/Res/generated/`（不直接覆盖现有素材，留对比空间）
- icon 类必须额外 `sips -z 1024 1024` 强制规范尺寸（gpt-image-2 实际产出可能是 1254 等）
- 截图允许并行多个 `codex exec`，但每条命令独占一个目标文件名
- 生成完用 `Read` 工具把 PNG 显示给用户检视，**不要**只口头说"已生成"

### Step 5 — 验收 & 交付

对每张产出执行：

```bash
sips -g pixelWidth -g pixelHeight -g hasAlpha <file>
file <file>   # 确认是 PNG，非 8MB+
```

验收清单：

- [ ] icon：1024×1024、`hasAlpha: no`、< 1MB
- [ ] 截图：尺寸精确匹配 Apple 要求、< 8MB、headline 拼写正确
- [ ] 视觉色板与 Step 2 选定的方向一致（不同张之间不能跑偏）
- [ ] 没有 Apple logo / 任何真实大学校徽 / 真实品牌商标
- [ ] icon 没有自带圆角（满边 1024 方形）

如果 AI 把 UI 内英文拼错（gpt-image-2 常见问题），有两条路：

1. 让 AI 只生成"设备外壳 + 背景 mockup"，UI 区留干净，再用 Xcode 真机截图合成
2. 改 prompt 把屏内文字简化（少字、大字、关键词）后重生

### Step 6 — 切片 icon（如用户需要）

icon 1024 → 14 个尺寸：

```bash
SET=<项目>/CambridgeDict/Resources/Assets.xcassets/AppIcon.appiconset
SRC=<项目>/Res/generated/app-icon.png
for spec in "1024:Icon-App-1024x1024@1x" \
            "180:Icon-App-60x60@3x" "120:Icon-App-60x60@2x" "120:Icon-App-40x40@3x" \
            "80:Icon-App-40x40@2x" "40:Icon-App-40x40@1x" \
            "87:Icon-App-29x29@3x" "58:Icon-App-29x29@2x" "29:Icon-App-29x29@1x" \
            "60:Icon-App-20x20@3x" "40:Icon-App-20x20@2x" "20:Icon-App-20x20@1x" \
            "167:Icon-App-83.5x83.5@2x" "152:Icon-App-76x76@2x" "76:Icon-App-76x76@1x"; do
  px="${spec%%:*}"; name="${spec##*:}"
  sips -z "$px" "$px" "$SRC" --out "$SET/${name}.png" >/dev/null
done
```

跑完检查 `Contents.json` 的 filename 与实际文件名一致。

## 多轮讨论的对话节奏

理想的一次完整调用应该长成：

1. **本 skill 介入** → 读项目 → 给 Project Brief
2. **给 3 个美学方向** → 用户选 / 改 / 否决
3. （循环 2 直到用户满意）
4. **给 prompt 集** → 用户 review 文案
5. （可能再调 prompt 一两个细节）
6. **跑生成命令** → 给用户看图
7. **挑选 / 重生不满意的某张** → 不要全部重跑
8. **可选**：切片 icon + 替换到 `Assets.xcassets`

不要把 1–8 一气呵成做完——节奏感来自每一步等用户确认。

## 反模式（不要做）

- ❌ 不读项目就生图
- ❌ 默认"现代简约渐变"这种没风格的方向
- ❌ 一次性生成所有资源不让用户看中间结果
- ❌ 用 `~` 路径或相对路径（codex sandbox 可能解析不到）
- ❌ icon 带 alpha / 带圆角 / 带阴影
- ❌ 截图里嵌 Apple logo 或真实大学校徽（会被审核打回）
- ❌ 生成完只口头汇报路径，不用 Read 显示图片给用户
