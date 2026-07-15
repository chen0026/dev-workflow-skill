---
name: dev-workflow
description: "Lightweight workflow for /dev-workflow, PRD, feature, bug, refactor, handoff, real verification, concise CHG records, precise commits, and history lookup."
---

# Dev Workflow Lite

默认直接开发，按需升级。不要为了执行流程而创建文档、运行 harness 或展开历史。

## Default Path

普通 Bug、功能、重构和维护任务默认：

1. 只读取 `AGENTS.md`、用户给出的需求和相关代码。
2. 定向确认调用链、影响范围、可复用能力和测试点。
3. 实现、测试、代码审查，用真实环境或真实接口完成最终验证。
4. 最终只输出：代码变更、验证结果、待提交文件、风险或未完成项。进入正式提交审核时再生成一个精简 `CHG` 和结构化 Git 记录。

开发过程中默认不创建 `ACTIVE / TASK / BUG / ACC / history`，不运行 harness、Loop 或索引脚本。

## Escalation

- **续作模式**：任务需要跨会话、换 agent、多人并行或用户明确要求交接时，只使用一个 `docs/active/ACTIVE-*.md`。
- **严格模式**：PRD 改版、多模块、接口契约、数据迁移、权限、支付、部署或其他高风险变更，编码前确认 `REQ` 和验收矩阵。
- 只有需求不清、验证失败或复杂任务需要切片时，才使用 harness 或 Loop。

## Hard Gates

- 默认不自动 commit；只有用户明确说“批准提交”或“确认提交”才提交。
- mock、fixture、stub 和 Playwright route mock 只能作为辅助测试，不能作为最终验收证据。
- 严格模式在 `REQ` 和验收项未经人工确认前不编码。
- 请求提交时才用 `commit-scope.sh prepare`分类当前工作区；批准后精确 stage/check。
- 正式代码提交默认恰好新增 1 个 `docs/changes/YYYY/MM/CHG-*.md`，与代码同 commit；临时提交或用户明确说“不留文档”时才跳过。
- CHG 只记录结构化元数据、原因、变更、验证和影响；不再配套创建 REQ、TASK、BUG 或 ACC。
- CHG 和 commit message 不得写入密钥、token、客户隐私、生产数据或其他敏感信息。
- 提交前必须向用户展示“文件范围 + CHG + 结构化 commit message”，三者确认后才提交。
- 并行任务优先使用独立 Git worktree；共享工作区时用 `--other` 标记其他任务文件。
- 新增或修改关键业务代码时，只在不注释难以理解的职责、业务原因或边界处补简短中文注释。

## Commands

- `/dev-workflow init [--hooks]`：初始化或升级项目。
- `/dev-workflow check|doctor|version`：按需检查。
- `/dev-workflow active ...`：仅用于跨会话或并行任务。
- `/dev-workflow loop ...`：仅用于复杂切片或验证失败。
- `/dev-workflow commit ...`：仅在进入人工提交审核时使用。
- `/dev-workflow history <关键词|文件>`：先定向搜索 CHG，再用 Git history 查询真实 diff。

## References

- 升级判定、文档预算和按需索引见 `references/flow.md`。
- ACTIVE、严格验收、真实验证和精确提交见 `references/details.md`。
