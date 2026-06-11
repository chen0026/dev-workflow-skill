# Details

## 项目接入

执行前检查：

1. 是否存在 `AGENTS.md`。
2. 是否存在 `docs/`。
3. `docs/` 是否已有旧文档。
4. 是否已有 `docs/workflow.md`、必要子目录和本地索引脚本；`docs/index.md` 不是必需文件。

处理规则：

- 没有 `AGENTS.md`：创建，并写入 dev-workflow 规则和文档查找优先级。
- 已有 `AGENTS.md`：保留原内容，只追加 dev-workflow 规则；如已有同类规则，先更新，不重复堆叠。
- 没有 `docs/`：创建标准目录骨架。
- 已有 `docs/` 但不是 dev-workflow 结构：把旧文档移动到 `docs/archive/legacy-docs-YYYYMMDD/`，再创建新结构。
- 已有 dev-workflow 结构：沿用，不覆盖已有文档。
- 归档旧文档前，先确认这些文件属于文档资料；不要移动代码、配置、脚本或构建产物。

## PRD 追踪矩阵

当任务来自 PRD、新功能、现有功能改版或产品文档时，不能直接编码。

必须先完成：

1. 拆出 `REQ` 需求追踪矩阵。
2. 每个 REQ 保留 PRD 原文依据。
3. 对比当前实现和目标行为。
4. 标注影响范围、风险和待确认问题。
5. 为每个 REQ 绑定 TASK、验收方式和测试计划。
6. 等待人工确认 REQ 矩阵。

REQ 未确认前，不创建实现代码，不修改业务代码。

## 需求一致性验收

完成前运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" verify "任务描述"
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" check
```

机器只检查完整性：

- 是否存在 REQ / TASK / BUG / ACC 等必要记录。
- REQ 是否包含验收方式或测试计划。
- 主记录或 ACC 是否包含验证证据。
- 文档预算是否超出当前流程级别。
- `docs/index.md` 是否仍被 Git 跟踪。

机器不得直接宣称需求一致。`verify` 输出 `requirement_match: pending-human-review` 时，最终回复必须列出需求、实现、验证证据和缺口，等待人工审核。

重点关注 `requirement_status / evidence_status / machine_gate`。`machine_gate: blocked` 必须先处理；`machine_gate: review` 必须在最终回复中解释原因并交给人工确认。

## TDD

新功能、PRD 改版、Bug 修复默认优先使用 TDD：

- 编码前先写测试或手工验收项。
- 每个测试或验收项必须关联 REQ / BUG。
- 有测试框架时，先确认目标测试失败，再编码让测试通过。
- 已有功能改版时，先记录当前行为，再写 PRD 目标行为测试。
- 没有测试框架或不适合自动化时，在最终摘要、主记录或 strict 的 ACC 里记录原因，并写手工验收项。

## 代码审查

代码审查是完成前门禁，但保持轻量：

- 小任务：执行自查，重点看需求偏离、无关改动、错误处理、测试缺口、文档同步。
- 复杂 / 高风险任务：使用 subagent 或人工做独立 review。
- 审查发现的问题必须先修复，或记录为遗留问题并关联后续 TASK。
- 审查结论回填到主记录；quick 可只在最终回复列出。

## 人工审核和提交

- 默认不自动 commit。
- 完成开发、验证、必要自查和文档同步后，最终回复必须列出待审核内容和待提交文件。
- 只有用户明确回复“批准提交”或“确认提交”后，才执行 commit。
- 如果用户要求调整，先修改并重新验证、审查、同步文档，再回到人工审核。
- 如果用户要求不提交，保留变更并说明当前状态。

## Session 状态文件

为减少长任务占用上下文，可以使用 `.dev-workflow/session/*-working.json`。

默认规则：

- quick：不用 session 状态文件。
- standard：超过一轮、涉及多个文件、或上下文可能变长时使用。
- strict：默认使用 session 状态文件，同时 REQ 是正式文档，不清理。

状态文件只存结构化摘要，不存完整 PRD 或大段代码：

```json
{
  "id": "TASK-xxx",
  "flow": "strict",
  "source": "REQ-xxx",
  "changed_files": [],
  "verification": [],
  "review": [],
  "doc_updates": [],
  "open_questions": []
}
```

清理规则：

- 完成验证、代码审查、文档同步，并确认 session 内容已合并到主记录或 strict 文档链路后，可以清理。
- 清理必须在最终回复中列出。
- 如果存在 `open_questions`、文档未同步、或无法确认已合并，不清理，列为未完成事项。

脚本：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/session-state.sh" create TASK-xxx
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/session-state.sh" list
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/session-state.sh" clean
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/session-state.sh" clean --apply
```

## Superpowers Integration

如果当前环境有 Superpowers，可以按阶段配合使用：

- 需求澄清：`brainstorming`，结论写入 PRD / REQ / TASK。
- 计划制定：`writing-plans`，任务拆解写入 TASK。
- Bug 定位：`systematic-debugging`，复现、路径、根因写入 BUG。
- 实现：`test-driven-development`，验证方式写入最终摘要、主记录或 strict 的 ACC。
- 并行执行：`subagent-driven-development`，各 subagent 结论写入主记录或 strict 文档链路。
- 完成验证：`verification-before-completion`，验证结果写入最终摘要、主记录或 strict 的 ACC。
- 代码审查：`requesting-code-review`，审查结论写入最终摘要、主记录或 strict 的 ACC。

dev-workflow 不替代 Superpowers，只负责建立追踪链路、沉淀关键结论、完成前检查文档，并在人工审核通过后提交。

## Subagent 使用规则

默认不使用 subagent。满足以下任一条件时才使用：

- 任务涉及多个独立模块。
- Bug 根因不明确。
- 需要并行调查代码路径、测试、文档或影响范围。
- 改动影响范围较大。
- 完成前需要独立 review 或 QA 检查。

subagent 输出按流程级别沉淀：

- quick：最终回复列出关键结论。
- standard：结论写入 TASK 或 BUG 主记录。
- strict：结论写入 PRD / REQ / TASK / BUG / ACC / ADR 中的对应位置。
