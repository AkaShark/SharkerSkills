---
type: dir-readme
---

# specs/ — SDD 流水线产物

每个 feature 一个子目录：`specs/<feature>/`，按流水线顺序生成三个文件：

```
specs/<feature>/
  ├── spec.md     ← sdd-spec  生成：做什么 + EARS 验收 + 非目标
  ├── design.md   ← sdd-design 生成：架构 + 关键决策 + 取舍（可选 Mermaid）
  └── tasks.md    ← sdd-tasks 生成：有序任务 + 依赖 / 涉及模块 / 验收
```

`<feature>` 用 kebab-case 短名（如 `user-login`、`image-cache`）。

- 这一层是**纵向 SDD 流水线**的产物；**横向知识复利**的产物在 `../knowledge/`。
- spec 开头会召回 `../knowledge/`，design 结尾会回写 `../knowledge/decisions/`，形成闭环。

> 借鉴 [cc-sdd](https://github.com/gotalab/cc-sdd)（原版存 `.kiro/`）+ [spec-kit](https://github.com/github/spec-kit)；我们裁剪为 spec→design→tasks 三产物，存 `.sdd/specs/`。
