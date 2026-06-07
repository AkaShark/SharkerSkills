---
name: solo-review-branch
description: 从混杂的功能分支里抽出「只有我自己改动」的独立 review 分支（git blame 作者过滤 + 功能路径双层隔离，自动收敛多次提交的来回 churn），并支持把工作分支的新改动增量同步过去。当用户说「拉个只含我改动的分支让我 review」「把我的改动单独抽出来」「同步新改动到 review 分支」「review 我自己写的代码」时触发。
---

# solo-review-branch

把工作分支上「只有我自己改的那部分」抽成一个干净的 review 分支，让我能像看 PR 一样对照真实代码 review 自己（或 AI 替我）写的功能。

## 何时使用

- AI 在工作分支写完代码，我要 review「只有我自己改动的部分」，但分支上混了别人 / 我自己其他功能的噪音
- "帮我拉一个只含我改动的 review 分支" / "把我的改动单独抽出来 review"
- "我又在工作分支提交了几个改动，同步到 review 分支"
- 想在 IDE / GitLens 里对照真实代码（带跳转、上下文）review 自己的功能，而不是干看 diff

## 何时不使用

- 想看整个分支的全部改动 —— 直接 `git diff base...HEAD` 即可，不必抽分支
- 想 review **别人**的代码 —— 本 skill 专门隔离「我自己」的那部分
- 分支上只有我一个作者、且只有一个功能 —— 直接 GitLens compare `工作分支 ↔ base` 就够，无需抽
- 想把改动合入 / 发 PR / 推远端 —— 这是**本地 review 工具**，只做隔离与查看，不做合并、不 push

## 依赖 / 工具

纯 `git`（`blame` / `diff` / `checkout` / `switch` / `commit` / `merge-base`）+ bash。无其他外部依赖，macOS 自带 git 即可。

## 核心原理（两层过滤）

工作分支的改动 = `我这个功能` + `别人的改动` + `我自己被 merge 进来的其他功能`。要精确留下第一项，需要**两层过滤**：

| 层 | 作用 | 去掉什么 | 手段 |
|---|---|---|---|
| **作者层**（核心） | 只留「我写的行」 | 别人的改动 | `git blame` 逐行作者 == 我 |
| **功能层**（可选） | 只留「这个功能」 | 我自己其他功能（如 merge 进来的别的活） | 路径 / 关键字 glob |

> 单用作者层：会把我自己 merge 进来的其他功能也算成「我的」。
> 单用功能层：会把同事在同一功能上的改动也留下。
> **两层都要**，才等于「只有我这个功能的改动」。

## 工作流程

### Step 1 — 确定 base 主干 与「我」的身份

```bash
WORK=$(git rev-parse --abbrev-ref HEAD)          # 当前功能工作分支
MY=$(git config user.email)                       # 用邮箱判作者比 name 稳
# base：优先用户指定；否则探测主干，再兜底 merge-base
BASE=${BASE:-$(git rev-parse --verify -q develop 2>/dev/null \
  || git rev-parse --verify -q origin/develop 2>/dev/null \
  || git rev-parse --verify -q main 2>/dev/null)}
git rev-parse --verify "$BASE" >/dev/null || { echo "base 无效，请指定主干 ref"; }
```

- 工作区必须干净（有未提交改动先让用户提交 / 暂存），否则建分支会带脏。
- **Acceptance**：`BASE` 是有效 ref；拿到 `$MY`；`git status --porcelain` 为空。

### Step 2 — 功能层：圈定这个功能的候选文件

```bash
git diff --name-only "$BASE...HEAD" > /tmp/all_changed.txt   # 三点 diff：自动收敛 churn
# 按功能关键字 + 你维护的「共享文件白名单」筛
grep -iE "$FEATURE_KW" /tmp/all_changed.txt | grep -E '\.(m|mm|h|swift|...)$' > /tmp/candidates.txt
```

- `FEATURE_KW`：功能关键字（如 `dubbing`），由用户给；拿不准就从分支名 / 改动最多的目录推断后**让用户确认**，不脑补。
- 公共文件（被功能逻辑改过、但文件名不含关键字的，如某个 `RecordViewController`）需人工补进候选白名单。
- **Acceptance**：`/tmp/candidates.txt` 非空，且用户认可范围。

### Step 3 — 作者层：blame 逐行分类（最关键，别踩坑）

```bash
> /tmp/keep.txt; > /tmp/drop.txt; > /tmp/mixed.txt
while read f; do
  # 只看「分支新增行」(blame 输出里非 ^boundary 的行)，统计作者
  authors=$(git blame -e "$BASE..HEAD" -- "$f" 2>/dev/null | grep -v '^\^' \
            | sed -E 's/.*<([^>]+)>.*/\1/' | sort -u)
  mine=$(echo "$authors" | grep -cx "$MY")
  others=$(echo "$authors" | grep -vx "$MY" | grep -c .)
  if   [ "$mine" -gt 0 ] && [ "$others" -eq 0 ]; then echo "$f" >> /tmp/keep.txt
  elif [ "$mine" -eq 0 ];                        then echo "$f" >> /tmp/drop.txt
  else echo "$f" >> /tmp/mixed.txt; fi          # 混写：整文件保留 + 标记
done < /tmp/candidates.txt
cat /tmp/mixed.txt >> /tmp/keep.txt              # mixed 默认并入 keep（整文件保留）
```

> ⚠️ **绝不能用 `git log --author=<我> --name-only` 判作者**：你的 **merge commit** 会把别人的文件也列成「你动过」，导致大量误判为混写。**必须 `git blame` 逐行**，只认「分支新增行」的实际作者。
>
> 混写文件**默认整文件保留**（review 不要紧不必编译），但要在报告里标出「这几个文件混了别人的行」，让用户心里有数；**不做行级裁剪**（会切出不完整文件）。

- **Acceptance**：keep / drop / mixed 三类齐全，`keep+drop` 行数 == 候选数；mixed 清单已记下待报告。

### Step 4 — 重建 review 分支（从 base 起，只拣我的文件）

```bash
BR=review/<feature>
git branch -D "$BR" 2>/dev/null
git switch -c "$BR" "$BASE"
# macOS xargs 不支持 -a：用 NUL 分隔
tr '\n' '\0' < /tmp/keep.txt | xargs -0 git checkout "$WORK" --
git commit -q -m "review: <feature> 净改动快照(仅本人改动, blame 口径)" \
  -m "Base: $BASE  Source: $WORK  Files: $(wc -l < /tmp/keep.txt|tr -d ' ')"
```

- **Acceptance**：`git diff --name-only "$BASE..$BR" | wc -l` == keep 数；抽查 `git diff --name-only "$BASE..$BR" | grep -if <drop关键字>` 为空（无被剔文件残留）。

### Step 5 — 报告 + 切回工作分支（不动原分支）

```bash
git switch "$WORK"        # review 分支保留待看，工作分支毫发无损
```

向用户输出：keep / drop / mixed 三类清单 + 净行数（`git diff --shortstat "$BASE..$BR"`）+ GitLens 查看指引：
`GitLens → Search & Compare → Compare References → review/<feature> ↔ <base>`。

- **Acceptance**：当前分支 == `$WORK`；`$BR` 存在。

### Step 6 — 增量同步（工作分支有新提交时）

```bash
git switch "$BR"
tr '\n' '\0' < /tmp/keep.txt | xargs -0 git checkout "$WORK" --   # 拣最新版
if git diff --cached --quiet; then echo "review 分支已是最新，无需同步"
else git commit -q -m "sync: <新提交摘要> (源 <sha>, 仅本人文件)"; fi   # 新改动单独成 commit
git switch "$WORK"
```

- 先重跑 Step 2–3，因为新提交**可能引入新功能文件**（需补进 keep）。
- 增量提交让新改动在 GitLens 里**单独成一个 commit**，便于只看「这次新增了什么」。
- **Acceptance**：`$BR` 的每个 keep 文件逐个 == `$WORK` HEAD（`git diff --quiet "$BR" "$WORK" -- <file>`）。

## 输入

- 当前处于功能工作分支，且工作区干净（脏则先提交 / 暂存）
- `BASE` 主干 ref（可指定，否则探测 `develop`/`origin/develop`/`main`，再兜底 `git merge-base`）
- 功能范围：关键字 `FEATURE_KW` + 公共文件白名单（可指定，否则推断后让用户确认）
- 我的 git 身份（自动 `git config user.email`）

## 输出

- 本地 `review/<feature>` 分支 = `BASE` + **仅我这个功能的净改动**（多次提交的 churn 已收敛、别人与我的其他功能已剔除）
- 一份分类报告：keep（我的）/ drop（剔除）/ mixed（混了别人行，已标记）+ 净行数
- GitLens "Compare References" `review/<feature> ↔ BASE` 的查看指引
- 同步模式：`review/<feature>` 上一个增量 commit（或「已是最新」提示）

## 反模式

- ❌ 用 `git log --author --name-only` 判作者 —— merge commit 污染，**必用 `git blame` 逐行**
- ❌ `xargs -a <file>`（macOS 不支持）—— 用 `tr '\n' '\0' | xargs -0`
- ❌ 在 review 分支上 build / 编译 —— 剔除了依赖文件，大概率编不过；它只用于看 diff
- ❌ 只按作者、漏掉功能层 —— 会把你自己 merge 进来的其他功能也算成「你的」
- ❌ 对混写文件硬做行级删除 —— 默认整文件保留 + 标记，别擅自裁出不完整文件
- ❌ 动到工作分支 / 自动 push —— review 分支是一次性本地快照，看完 `git branch -D review/<feature>` 即可，原分支与远端零影响
- ❌ 工作区脏就建分支 —— 先确认 `git status` 干净，避免把别处改动带进快照

## 示例

- "配音功能写完了，拉个只含我改动的分支让我 review" → 生成 `review/peiyin`，自动剔除同事写的入口模块和 merge 进来的礼物代码，报告里标出 2 个混写的 model 文件
- "我又在工作分支提交了几个 fix，同步到 review 分支" → 重扫范围 → 增量提交，新 fix 在 GitLens 里单独成一个 commit
- "这次分支只有我一个人改，还需要抽吗" → 不需要，直接 GitLens compare 工作分支 ↔ base
