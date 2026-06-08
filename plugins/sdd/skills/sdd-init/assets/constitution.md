---
type: constitution
status: stable
created: {{DATE}}
updated: {{DATE}}
---

# 项目宪法 (Constitution)

> 这是项目的**稳定治理原则**——「法律」层。**人写为主、极少变**。
> SDD 各阶段（spec / design / tasks / impl）都会参考它。
> 与 `knowledge/`（AI 自动积累的「判例 + 笔记」，演进层）**分层**：宪法定原则，知识库记经验。
>
> 借鉴自 [spec-kit](https://github.com/github/spec-kit) 的 `/speckit.constitution`（原版写入 `.specify/memory/constitution.md` 贯穿全流程）；我们改名 `.sdd/constitution.md`，并明确把它定位为「稳定层」，与自动生长的 `knowledge/` 分层。

## 1. 技术栈红线
- <语言 / 框架 / 版本约束，例如：仅用 TypeScript strict 模式，Node ≥ 20>
- <禁用的依赖 / 反模式，例如：不引入新的状态管理库>

## 2. 代码质量
- <例如：必须 TDD —— 先写失败测试，再写实现>
- <例如：单文件 < 400 行；公共函数必须有类型签名>

## 3. 测试标准
- <例如：核心逻辑覆盖率 ≥ 80%；CI 全绿才能合并>
- <例如：每个 bug 修复必须附带一个回归测试>

## 4. 架构边界
- <例如：模块间只走公开接口，绝不跨目录直接 import 内部实现>
- <例如：UI 层不含业务逻辑，副作用集中在 service 层>

## 5. 一致性 / UX / 性能（按需保留）
- <例如：所有面向用户文案走 i18n>
- <例如：关键路径 P95 < 200ms>

---

> **维护纪律**：本文件是全流程的约束源，修改需谨慎。
> 日常经验（某次 debug 的坑、某个有取舍的决策、某个复用模式）请沉淀进 `knowledge/`，**不要**写到这里——宪法只放稳定不变的原则。
> 在 SDD 流程里，宪法可视为 `knowledge/` 里一个特殊的、只读的顶层页。
