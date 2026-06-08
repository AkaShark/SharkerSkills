# sharker-sdd 设计蓝图

> 在 SharkerSkills marketplace 新增一个 `sharker-sdd` plugin:把「通用 SDD 开发流水线」+「工程知识库(AI 自动积累 & 召回)」打包成可一键启用的能力。本文件是施工图纸 —— 实现阶段照此推进。
>
> 状态:**设计已定稿,待实现**。生成于 2026-06-08。

---

## 0. 一句话定位

> 装上 `sharker-sdd`,在任意新项目里 `/sharker-sdd:sdd-init` 一次 → 项目获得一套 SDD 流水线 + 一个会自我生长的工程知识库;之后按 spec→design→tasks→impl 开发,**开发过程中产生的知识自动沉淀,下次开工自动召回**,形成复利闭环。

SharkerSkills 现有三个 plugin(common/ios/tool)装的是**离散工具**;`sharker-sdd` 是第一个装**工作流/方法论**的 plugin。

---

## 1. 已锁定的决策(6 轮讨论结论,固化)

| 决策 | 结论 | 备注 |
|---|---|---|
| **方向** | 放弃自建"多工具同步"轮子,并入 SharkerSkills | rulesync 等已成熟,不重复造 |
| **D1 形态** | 两者结合:skill 提供命令入口,命令负责在项目里铺文件 | cc-sdd 即此模式 |
| **D2 开源借鉴** | 可以抄优秀开源框架,但**每个借鉴点必须透明标注**:借鉴自谁 / 原版怎么做 / 我们改了什么 | 见 §7 |
| **D3 边界** | SDD 并进 SharkerSkills,作为新 plugin `sharker-sdd` | 不另起独立项目 |
| **KB 写入** | AI 自主判断为主 + `/kb-save` 手动兜底 | karpathy 的 schema=行为协议思路 |
| **KB 召回** | **先不上 RAG/embedding**:结构化 markdown + `index.md` + 按需读 | <100k token 全量进 context 胜过 RAG |
| **KB↔SDD** | **紧耦合**:SDD 各阶段自动喂知识库 + 开工前自动召回 | 复利闭环的关键 |

---

## 2. 整体架构

```
SharkerSkills marketplace
├── sharker-common / ios / tool        ← 现有离散工具,不动
└── sharker-sdd  ★新增 plugin★
        skills/
          ├── sdd-init     一键铺项目脚手架(.sdd/ 目录)
          ├── sdd-spec     需求 → spec.md     (开头:召回知识库)
          ├── sdd-design   spec → design.md   (结尾:沉淀决策到 knowledge/decisions)
          ├── sdd-tasks    design → tasks.md
          ├── sdd-impl     执行(TDD+逐任务review;debug 沉淀到 knowledge/lessons)
          ├── kb-save      手动沉淀兜底 (AI 自主沉淀的显式入口)
          ├── kb-query     召回:按 index 找相关页并综合
          └── kb-lint      防腐巡检:查矛盾/过时/孤儿页
                    │ sdd-init 在被开发的项目里铺出 ↓
   <你的项目>/.sdd/
        ├── constitution.md   项目宪法(稳定原则,人写为主)         [借鉴 spec-kit]
        ├── schema.md         告诉 AI 怎么维护知识库(行为协议)      [借鉴 karpathy]
        ├── specs/<feature>/  spec.md / design.md / tasks.md       [借鉴 cc-sdd + spec-kit]
        └── knowledge/        工程知识库(AI 自动积累)              [借鉴 karpathy LLM Wiki]
              ├── index.md        召回入口:所有知识页的清单+一句话摘要
              ├── modules/        模块/组件实体页(这块代码干什么、为什么这样写)
              ├── decisions/      架构决策记录(ADR)
              ├── lessons/        踩坑教训(debug 沉淀)
              └── patterns/       代码模式/约定
```

**两条数据流**:
- **纵向(SDD 流水线)**:需求 → spec → design → tasks → impl → 可工作的代码
- **横向(知识复利)**:开发事件 → 沉淀进 knowledge/ → 下次开工召回 → 不重复踩坑

---

## 3. SDD 流水线设计

### 3.1 阶段与产物

| Skill | 输入 | 产物 | 知识库挂钩(紧耦合) |
|---|---|---|---|
| `sdd-init` | 项目根目录 | `.sdd/` 全套脚手架 | 初始化空 `knowledge/index.md` + `schema.md` |
| `sdd-spec` | 一句话需求 | `specs/<feat>/spec.md`(要做什么+验收标准) | **开头**先读 `knowledge/index.md` 召回相关历史 |
| `sdd-design` | spec.md | `specs/<feat>/design.md`(架构+技术方案) | **结尾**把架构决策写入 `knowledge/decisions/` |
| `sdd-tasks` | design.md | `specs/<feat>/tasks.md`(有序任务+依赖标注) | 任务里标注"涉及哪些 modules/" |
| `sdd-impl` | tasks.md | 代码 + 测试 | **过程中** debug 成功后把坑写入 `knowledge/lessons/`;完成后更新 `modules/` |

### 3.2 spec.md / design.md / tasks.md 模板

- **spec.md**:目标、用户故事、验收标准(可借鉴 cc-sdd 的 EARS 格式:`When <条件>, the system shall <行为>`)、非目标
- **design.md**:架构概述、关键决策(每条配「为什么/备选/取舍」)、文件结构、(可选 Mermaid 图)
- **tasks.md**:有序任务列表,每条带 `[依赖: ...]`、`[涉及模块: ...]`、`[验收: ...]`

### 3.3 与现有 OMC agent 的关系

`sdd-impl` 的执行交给 OMC 的 `executor`(复杂任务 `model=opus`),review 交给 `code-reviewer`/`verifier`。**SDD skill 是流程编排层,不重造执行 agent。**

---

## 4. 工程知识库设计(核心,借鉴 karpathy「LLM Wiki」)

### 4.1 karpathy 原版怎么做的

- **三层**:raw sources(只读) / wiki(LLM 完全拥有的结构化 md) / schema(CLAUDE.md,定义结构与工作流的行为协议)
- **三操作**:Ingest(吸收新信息织进现有页)、Query(查询并回填)、Lint(查矛盾/过时/孤儿页)
- **核心论点**:<100k token(~200 页)时,AI 维护的互联 markdown wiki **吊打 RAG** —— 100% 检索可靠、无 chunking 损失、零基建。LLM 最擅长人类最烦的"记账"(跨页更新交叉引用)。

### 4.2 我们怎么改(适配工程场景)

| 维度 | karpathy 原版 | sharker-sdd 改法 |
|---|---|---|
| 知识来源 | 用户喂的外部文档(论文/文章) | **开发过程本身**(debug/决策/模式) |
| Ingest 触发 | "新文档到达" | "开发事件发生"(修完 bug、定完方案、做完 feature) |
| 实体页类型 | entity / concept 页 | `modules/` `decisions/` `lessons/` `patterns/` 四类工程实体 |
| schema 载体 | 项目根 `CLAUDE.md` | 独立 `.sdd/schema.md`(避免污染项目主 CLAUDE.md) |
| 触发机制 | 人工调用 | **AI 自主(schema 行为协议)+ `/kb-save` 兜底** |

### 4.3 三操作的落地

- **Ingest(写入)**:
  - *AI 自主*:`schema.md` 里写明行为协议 —— "当你 (a) debug 成功定位一个非显然的坑 (b) 做出一个有取舍的架构决策 (c) 发现一个会复用的模式 时,把它 ingest 进对应目录,并更新 `index.md`"。SDD 各 skill 在关键节点显式触发(见 §3.1 挂钩)。
  - *手动兜底*:`kb-save` skill —— 用户说"把这个记下来"时,结构化成知识页写入。
  - *写入纪律*:每页 front-matter 带 `created/updated/source(commit或spec)/tags`;互相用 `[[page-name]]` 链接(karpathy 模式);写完必须回写 `index.md` 一行摘要。
- **Query(召回)**:`kb-query` skill,也被 `sdd-spec` 开头自动调用。流程:读 `index.md` → 按 tags/关键词判断相关页 → 只读那几页 → 综合回答并标注来源页。**不做 embedding,纯 grep + 按需读。**
- **Lint(防腐)**:`kb-lint` skill。检查:① 矛盾(两页说法冲突)② 过时(对照当前代码验证 lesson/module 是否还成立)③ 孤儿页(没被 index 或任何 `[[链接]]` 引用)④ 缺失交叉引用。产出报告 + 建议修复,不自动删。

### 4.4 召回规模红线

`index.md` + 单次召回读入的页面总量控制在 **~50k token 以内**。一旦 `knowledge/` 增长到威胁这条线(lint 时告警),再考虑分领域子 index 或引入检索 —— 但**不是现在**。这条红线明确写进 `schema.md`。

---

## 5. 紧耦合闭环(让知识库"活"起来)

```
        ┌──────────────────────────────────────────┐
        │                                          │
        ▼                                          │
  sdd-spec ──开头──▶ 读 knowledge/index.md (召回)    │
        │           "这个 feature 历史上有相关坑吗?"  │
        ▼                                          │
  sdd-design ──结尾──▶ 写 knowledge/decisions/  ─────┤
        │             (本次架构决策+取舍)            │
        ▼                                          │ 复利:
  sdd-impl ──debug成功──▶ 写 knowledge/lessons/ ─────┤ 下个 feature
        │             ──完成──▶ 更新 knowledge/modules/│ 自动受益
        ▼                                          │
   可工作的代码                                      │
        └──────────────────────────────────────────┘
```

**实现机制(分两层,先简后繁)**:
1. **prompt 层(先做)**:把召回/沉淀步骤**内建进各 SDD skill 的工作流 Step**(带 Acceptance)。这是 cc-sdd 的做法 —— 流程即协议,无需额外基建。
2. **hook 层(后做,可选)**:加一个 `Stop` 或 `SessionEnd` hook,会话结束时提示"本次有 N 处可沉淀的知识,是否 `/kb-save`?"。hook 配置走 `update-config` skill 写进 `settings.json`。**v1 不做,留接口。**

---

## 6. constitution(项目宪法,借鉴 spec-kit)

- **spec-kit 原版**:`/speckit.constitution` 生成 `.specify/memory/constitution.md`,作为贯穿全流程的"治理原则"(代码质量/测试标准/UX 一致性/性能要求),agent 在 specify/plan/implement 各阶段都参考它。
- **我们的改法**:`sdd-init` 生成 `.sdd/constitution.md` 模板,内容是**项目级稳定原则**(如"必须 TDD"、"绝不跨目录改"、技术栈红线)。
- **与知识库的分层**(关键区分):
  - `constitution.md` = **稳定的"法律"**(人写,极少变)
  - `knowledge/` = **演进的"判例+笔记"**(AI 自动积累)
  - 宪法可视为知识库里一个特殊的、只读的顶层页;SDD 各阶段同时参考二者。

---

## 7. 开源借鉴透明标注表(D2 要求 —— 每个 skill 的 SKILL.md 里也要复述对应行)

| 我们的部分 | 借鉴自 | 原版怎么做 | 我们改了什么 |
|---|---|---|---|
| SDD 阶段链 spec→design→tasks→impl | [cc-sdd](https://github.com/gotalab/cc-sdd) | `/kiro-spec-init`→requirements(EARS)→design(Mermaid)→tasks→impl(TDD+自动debug),存 `.kiro/` | 裁剪为 5 skill;存 `.sdd/`;impl 复用 OMC executor 而非自带 |
| `npx` 一键 init 脚手架 | [cc-sdd](https://github.com/gotalab/cc-sdd) | `npx cc-sdd@latest` 写入项目结构 | 改为 Claude Code skill `sdd-init`(无 npm 依赖,贴合 SharkerSkills 纯文件分发) |
| EARS 验收格式 / Mermaid 设计图 | cc-sdd | requirements.md 用 EARS,design.md 带 Mermaid | 可选采用,作为 spec/design 模板的推荐写法 |
| constitution 项目宪法 | [spec-kit](https://github.com/github/spec-kit) | `/speckit.constitution` → `.specify/memory/constitution.md` 贯穿全流程 | 改名 `.sdd/constitution.md`;明确定位为"稳定层",与自动知识库分层 |
| clarify 澄清环节(可选) | spec-kit | `/speckit.clarify` 在 plan 前结构化提问降返工 | 暂作为 `sdd-spec` 内的一个可选 Step,不单列 skill |
| 知识库 = AI 维护的互联 wiki | [karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) | raw/wiki/schema 三层 + ingest/query/lint 三操作;<100k token 不上 RAG | 知识源改为开发过程;四类工程实体页;AI 自主+`/kb-save` 触发;schema 独立成文件 |
| learnings 自动沉淀到目录 | [AddyOsmani self-improving agents](https://addyosmani.com/blog/self-improving-agents/) | 把每次 learnings/errors/corrections 记进 `.learnings/` | 并入 `knowledge/lessons/`,由 SDD impl 阶段触发 |

---

## 8. 与 SharkerSkills 约定的对齐(实现时必须遵守)

1. **新建 plugin 需手动 scaffold**(skill-creator 不能建新 plugin):
   - 建 `plugins/sdd/.claude-plugin/plugin.json`(name=`sharker-sdd`,**不带 `$schema`**)
   - 建 `plugins/sdd/skills/`
   - 在 `marketplace.json` 的 `plugins[]` 增一条 `source: "./plugins/sdd"`(含 name/description/version/author/category/homepage/tags)
2. **每个 skill 遵循 10 节 SKILL.md 结构**:frontmatter(name/description)→ tagline → 何时使用 → 何时不使用 → 依赖/工具 → 工作流程(Step+Acceptance)→ 输入 → 输出 → 反模式 → 示例。
3. **带脚本/模板的 skill 可用多文件**(参考 picgo-upload 的 `scripts/`):init 的脚手架模板放 `skills/sdd-init/assets/`。
4. **版本**:`sharker-sdd` 从 `0.1.0` 起;两站点(plugin.json + marketplace 条目)一致。
5. **README**:加 `### sharker-sdd` 小节 + 锚点 `<!-- skills:sharker-sdd -->` + 安装命令 `/plugin install sharker-sdd@sharker-skills`。
6. **不动 git**:实现产出文件后,commit/push 由用户手动做。

---

## 9. 分阶段实施计划

| Phase | 内容 | 产物 | 可独立验证 |
|---|---|---|---|
| **P1 Scaffold** | 手动建 `sharker-sdd` plugin 骨架 + 加入 marketplace + README 小节 | plugin.json / marketplace 条目 / README | `/plugin install` 能识别空 plugin |
| **P2 init** | `sdd-init` skill + `.sdd/` 脚手架模板(constitution/schema/空 knowledge/specs) | `skills/sdd-init/` + `assets/` 模板 | 在测试项目跑 `sdd-init` 铺出完整 `.sdd/` |
| **P3 SDD 链** | `sdd-spec`/`sdd-design`/`sdd-tasks`/`sdd-impl` 四 skill(内建知识库挂钩) | 四个 SKILL.md | 跑一个玩具 feature 走完 spec→impl |
| **P4 知识库** | `kb-save`/`kb-query`/`kb-lint` 三 skill + schema 行为协议定稿 | 三个 SKILL.md | 沉淀→召回→lint 闭环可跑 |
| **P5 收尾** | 紧耦合联调、(可选)hook、文档、attribution 复述进各 SKILL.md | 完整 plugin v0.1.0 | 端到端:init→开发→自动沉淀→下次召回 |

**建议节奏**:P1+P2 先做(一次能看到 `sdd-init` 真在项目里铺出东西),P3/P4 各一轮,P5 收口。每个 Phase 是一次可提交的增量。

---

## 10. 待定/开放问题

- [ ] `.sdd/` 这个目录名是否 OK?(备选 `.spec/`、复用 cc-sdd 的 `.kiro/`)—— 倾向 `.sdd/`,自解释。
- [ ] EARS 格式是强制还是推荐?—— 倾向推荐,不强制。
- [ ] knowledge 的 ingest 在 v1 是否要做"自动"还是先全靠 SDD skill 节点触发 + `/kb-save`?—— 倾向后者(prompt 层),hook 留 P5+。
- [ ] 是否要把 `sharker-sdd` 也支持 Codex?—— 否(对齐 SharkerSkills「Claude Code 专用」定位)。

---

## 11. 下一步

实现涉及改 `marketplace.json`(jq mutation)、跑 git/版本校验、在测试项目 smoke test —— **建议在 SharkerSkills 工作仓库目录开一个会话**照本蓝图从 **P1** 开始施工(原生 cwd 下 git/jq/测试都顺畅,避免跨目录别扭)。本蓝图即施工图。
