---
type: dir-readme
---

# lessons/ — 踩坑教训

每个文件记录**一个非显然的坑**：现象、根因、复现条件、正确做法。这是知识库里**最具体、最值钱**的一类页。

- 触发：debug 成功定位到一个不直观的根因后（`sdd-impl` 自动沉淀；不是 typo / 一眼可见的错误）。
- 文件名：现象/根因短语，如 `oauth-token-refresh-race.md`、`sqlite-locked-on-fork.md`。
- 模板见 `../../schema.md` §3.1（type=lesson）；写完回写 `../index.md`。

> 借鉴 [AddyOsmani self-improving agents](https://addyosmani.com/blog/self-improving-agents/) 的「learnings 自动沉淀」，并入本目录、由 SDD impl 阶段触发。
