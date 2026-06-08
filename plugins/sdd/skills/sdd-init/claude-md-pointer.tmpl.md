<!-- sharker-sdd:knowledge-base BEGIN (此块由 /sharker-sdd:sdd-init 注入；不喜欢可整段删除，无副作用) -->
## 工程知识库（sharker-sdd）

本项目启用 `.sdd/` 工程知识库。**凡涉及知识读写，遵循 `.sdd/schema.md` 的行为协议**（此处仅摘要，全文在 schema.md）：

- **召回**：动手解决问题前，先读 `.sdd/knowledge/index.md`，按相关性只读命中的几页（grep + 按需读，不上 embedding）。
- **沉淀**（满足条件就主动写，宁缺毋滥）：
  - debug 定位到**非显然**的坑 → `.sdd/knowledge/lessons/`
  - 做出**有取舍**的架构决策 → `.sdd/knowledge/decisions/`
  - 发现**可复用**的模式 / 约定 → `.sdd/knowledge/patterns/`
  - 完成 / 显著改动一个模块 → 更新 `.sdd/knowledge/modules/`
- 每次写知识页**都回写** `.sdd/knowledge/index.md`（一行摘要 + 统计），并用 `[[page]]` 互链。
- 召回总量守 **~50k token** 红线（详见 `.sdd/schema.md` §6）。
<!-- sharker-sdd:knowledge-base END -->
