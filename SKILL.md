---
name: dev-workflow
description: "Lightweight workflow for /dev-workflow, PRD, feature, bug, refactor, unified DEV records, real verification, precise commits, and Git history lookup."
---

# Dev Workflow Lite

默认直接开发，按需升级。不要为了执行流程而创建文档、运行 harness 或展开历史。

## Default Path

普通 Bug、功能、重构和维护任务默认：

1. 只读取 `AGENTS.md`、用户给出的需求和相关代码。
2. 定向确认调用链、影响范围、可复用能力和测试点。
3. 为本线程生成稳定 TASK_KEY；首次修改每个文件前由 Agent 后台执行 `commit-scope.sh track TASK_KEY -- FILE...`，然后实现、测试和审查。
4. 最终只输出：代码变更、验证结果、待提交文件、风险或未完成项。正式提交只生成结构化 Git 记录。

开发过程中默认不创建 `ACTIVE / TASK / BUG / ACC / history`，不运行 harness、Loop 或索引脚本。

## Escalation

- **续作模式**：任务需要跨会话、换 agent、多人并行或用户明确要求交接时，只使用一个 `docs/active/ACTIVE-*.md`。
- **严格模式**：PRD 改版、多模块、接口契约、数据迁移、权限、支付、部署或其他高风险变更，只创建一个 `DEV` 生命周期文档，编码前确认需求基线和验收矩阵。
- 只有需求不清、验证失败或复杂任务需要切片时，才使用 harness 或 Loop。

## Hard Gates

- 默认不自动 commit；先一次性展示完整审核包，再等待一次明确批准。
- mock、fixture、stub 和 Playwright route mock 只能作为辅助测试，不能作为最终验收证据。
- 严格模式在 `DEV` 的需求基线和验收项未经人工确认前不编码。
- 请求提交时才用 `commit-scope.sh prepare TASK_KEY`记录本任务文件；批准后用 `commit-scope.sh commit TASK_KEY ...`精确提交。
- 已使用 `track`的线程直接复用并增量合并自己的文件记录，不得在提交前重建或缩小范围；用户不需要操作这些命令。
- 普通 Bug、功能、重构和维护不创建 CHG、REQ、TASK、BUG 或 ACC；Git commit 是修改历史的唯一事实记录。
- 复杂任务使用一个 `docs/work/YYYY/MM/DEV-*.md`贯穿需求、计划、问题、验收和关联 commits，不拆配套文档。
- DEV 和 commit message 不得写入密钥、token、客户隐私、生产数据或其他敏感信息。
- 完整审核包包含“文件范围 + 完整 commit message + 验证结果”；如当前任务使用 DEV，再包含 DEV 变化。不得分批确认。
- 用户在完整审核包后回复“提交代码 / 确认提交 / 批准提交”即为最终授权；随后立即精确暂存并提交，不得为暂存、hooks 或 commit 再次询问。
- 只有授权后文件范围、DEV、commit message 或验证结论发生变化时，才展示变化并重新确认一次。
- 共享工作区为每个任务保存独立 manifest，并使用 `git commit --only`保留其他任务暂存状态；不同任务包含同一文件时才阻断。
- 同一文件已被其他线程记录时，在修改前停止；普通情况下仍由当前线程提交自己的文件，不要求统一收口。
- 只有 commit 命令成功、HEAD 实际变化、HEAD 文件与本线程记录一致且这些文件无残留时，才能声称提交成功；否则必须明确报告阻断或失败。
- 新增或修改关键业务代码时，只在不注释难以理解的职责、业务原因或边界处补简短中文注释。

## Commands

- `/dev-workflow init [--hooks]`：初始化或升级项目。
- `/dev-workflow check|doctor|version`：按需检查。
- `/dev-workflow active ...`：仅用于跨会话或并行任务。
- `/dev-workflow loop ...`：仅用于复杂切片或验证失败。
- `/dev-workflow commit ...`：仅在进入人工提交审核时使用。
- `/dev-workflow history <关键词|文件>`：先用 Git history 查询真实 diff；复杂任务再定向读取关联 DEV。

## References

- 升级判定、文档预算和按需索引见 `references/flow.md`。
- ACTIVE、严格验收、真实验证和精确提交见 `references/details.md`。
