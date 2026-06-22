# Details

## 项目接入

执行前检查：

1. 是否存在 `AGENTS.md`。
2. 是否存在 `docs/`。
3. `docs/` 是否已有旧文档。
4. 是否已有 `docs/workflow.md`、`docs/active/`、`docs/history/`、必要子目录和本地索引脚本；`docs/index.md` 不是必需文件。

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

## 编码前文档确认

这是执行代码前的硬门禁：

- quick：不要求正式文档确认。
- standard：默认先创建或更新一个 `ACTIVE` 交接文件，写清目标、范围、不做什么、验收项和测试方式；复杂或高风险才升级 `TASK` / `BUG`。
- strict：先创建或更新 `REQ`，写清 PRD 依据、当前实现、目标行为、验收方式和测试计划。
- standard / strict：编码前必须写测试用例清单，并等待人工确认。
- 用户确认文档后，才能把对应文档的 `编码前确认` 改为 `已确认`。
- 用户确认测试清单后，才能把对应文档的 `测试用例确认` 改为 `已确认`。
- `编码前确认：已确认` 和 `测试用例确认：已确认` 之前，不创建或修改业务代码。

这一步是“施工许可”，不是完成后的记录。完成后仍要回填实际改动、验证、代码审查和验收结论。

## ACTIVE 和 history

ACTIVE 解决“任务做到一半换 agent 不知道进度”的问题，history 解决“每个小 bug 都永久新增大文档”的问题。

- 一个进行中任务只保留一个 `docs/active/ACTIVE-*.md`；不要创建全局 `current-work.md`。
- 多线程、多分支、多电脑并行时，用不同 ACTIVE 文件并行，不互相覆盖。
- ACTIVE 必须记录状态、目标、不做什么、范围、下一步、阻塞项、测试用例清单、真实验证证据和代码审查结论。
- 任务未完成或存在待确认问题时，保留 ACTIVE，作为下一位 agent 的交接入口。
- 任务完成并通过人工审核后，把 8 行以内摘要追加到 `docs/history/<module>.md`，再删除 ACTIVE。
- history 只写完成结论：类型、原因、改动、验证、审查、提交和关联编号；不要把过程全文搬进去。
- 后续再次修改同一功能：如果旧 ACTIVE 未完成，继续更新旧 ACTIVE；如果旧任务已完成，先读模块 history，再新建 ACTIVE 或正式文档。
- TASK / BUG / ACC 只在复杂、高风险、长期追溯或用户明确要求时创建；普通任务用 ACTIVE + history 即可。

辅助脚本：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/active-work.sh" start file-manager-rename
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/active-work.sh" list
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/active-work.sh" template
```

完成并通过人工审核后，用 `active-work.sh finish ACTIVE_FILE module-name < summary.md` 折叠到 history；摘要最多 8 个非空行。

## Adaptive Loop Engineering

Loop 是执行节奏控制，不是新的文档负担。每轮只做一个可验证动作：

```text
理解当前状态 -> 选择一个小动作 -> 执行 -> 验证证据 -> 决定继续 / 修正 / 停止 / 等人确认
```

harness 输出：

- `loop_phase`：`intake / slice / pre_code_doc / implement / verify / review / human_gate / done`。
- `loop_next_decision`：`continue / retry / wait_human / stop`。
- `max_iterations`：quick 1，standard 3，strict 5。
- `stop_condition`：本轮何时必须停止。
- `slice_strategy`：是否需要自适应切片。

自适应切片规则：

1. 优先按需求文档自身结构切：标题、章节、表格、用户流程、角色、状态、规则。
2. 再按项目代码边界切：页面、组件、接口、服务、模型、任务、测试。
3. 再按风险点切：数据、权限、金额、状态机、外部系统、部署、兼容、性能。
4. 最后按可验证粒度切：每个 slice 必须能独立实现、验证、暂停或回滚。

不套固定业务分类。风险点只是提示 agent 单独暴露和确认，不代表所有 PRD 都必须拥有这些分类。

停止规则：

- `loop_next_decision: wait_human`：必须停下等待人工确认。
- `loop_next_decision: stop`：必须说明阻断原因、证据和下一步。
- 达到 `max_iterations` 仍未通过验证：停止并汇报，不继续猜测。
- 发现需求歧义、影响范围扩大、无法定位真实实现路径、验证证据不足：停止并列待确认问题。

## 需求一致性验收

完成前运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" verify "任务描述"
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" check
```

机器只检查完整性：

- 是否存在 REQ / ACTIVE / TASK / BUG / ACC 等必要记录。
- REQ 是否包含验收方式或测试计划。
- ACTIVE、主记录或 ACC 是否包含验证证据。
- 文档预算是否超出当前流程级别。
- `docs/index.md` 是否仍被 Git 跟踪。

机器不得直接宣称需求一致。`verify` 输出 `requirement_match: pending-human-review` 时，最终回复必须列出需求、实现、验证证据和缺口，等待人工审核。

重点关注 `requirement_status / evidence_status / machine_gate`。`machine_gate: blocked` 必须先处理；`machine_gate: review` 必须在最终回复中解释原因并交给人工确认。

## 真实验证门禁

最终验收默认真实验证优先，不允许把 mock 当成降级验收：

- 可作为最终证据：真实后端、真实接口、真实运行环境、本地前后端联调、测试环境、真实数据链路、人工实测记录。
- 不可作为最终证据：mock 数据、fixture、stub、MSW、Playwright route mock、接口拦截、模拟接口、仅前端假数据。
- mock 只能用于开发辅助、组件孤立测试、异常态/空态补充测试；它可以记录为补充证据，但不能独立支撑“需求已完成”。
- 如果真实环境不可用，任务状态是 `blocked` 或 `pending-real-verification`，不是验收通过。
- 最终回复和 ACTIVE / TASK / BUG / ACC 必须写清最终验收来源、最终验收证据、是否存在辅助模拟测试。

`verify` 输出 `verification_source_status: mock_only_final_evidence` 时，必须补真实验证证据后再进入人工审核。

## TDD

新功能、PRD 改版、Bug 修复默认优先使用 TDD：

- 编码前先写测试用例清单，再写测试或手工验收项。
- 每个测试或验收项必须关联 ACTIVE / REQ / BUG，不能只关联实现文件或函数名。
- 测试用例必须描述用户行为或业务规则，包含场景、前置状态、操作、期望结果、测试类型、真实验证路径、mock 使用限制和 RED 失败记录。
- 有测试框架时，先确认目标测试失败，再编码让测试通过。
- 已有功能改版时，先记录当前行为，再写 PRD 目标行为测试。
- 没有测试框架或不适合自动化时，在最终摘要、主记录或 strict 的 ACC 里记录原因，并写手工验收项。
- 如果测试用例无法从 ACTIVE / REQ / BUG 推导，说明需求仍不清楚，停止并回到待确认问题。
- 如果 `verify` 输出 `test_case_status: missing_test_case_confirmation` 或 `missing_test_case_quality_fields`，必须补齐并重新确认后再继续。

## 代码审查

代码审查是完成前门禁，但保持轻量：

- 小任务：执行自查，重点看需求偏离、无关改动、错误处理、测试缺口、文档同步。
- 复杂 / 高风险任务：使用 subagent 或人工做独立 review。
- 审查发现的问题必须先修复，或记录为遗留问题并关联后续 TASK。
- 审查结论回填到 ACTIVE 或主记录；quick 可只在最终回复列出。

## 人工审核和提交

- 默认不自动 commit。
- 完成开发、验证、必要自查、ACTIVE 折叠或正式文档同步后，最终回复必须列出待审核内容和待提交文件。
- 只有用户明确回复“批准提交”或“确认提交”后，才执行 commit。
- 如果用户要求调整，先修改并重新验证、审查、同步文档，再回到人工审核。
- 如果用户要求不提交，保留变更并说明当前状态。

## Session 状态文件

为减少长任务占用上下文，可以使用 `.dev-workflow/session/*-working.json`。

默认规则：

- quick：不用 session 状态文件。
- standard：优先用 ACTIVE 承载交接；只有超过一轮、涉及多个文件、或需要机器结构化摘要时再使用 session 状态文件。
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

- 完成验证、代码审查、文档同步，并确认 session 内容已合并到 ACTIVE、history 或 strict 文档链路后，可以清理。
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

- 需求澄清：`brainstorming`，结论写入 ACTIVE、PRD、REQ 或 TASK。
- 计划制定：`writing-plans`，任务拆解写入 ACTIVE 或 TASK。
- Bug 定位：`systematic-debugging`，复现、路径、根因写入 ACTIVE 或 BUG。
- 实现：`test-driven-development`，验证方式写入最终摘要、ACTIVE、主记录或 strict 的 ACC。
- 并行执行：`subagent-driven-development`，各 subagent 结论写入 ACTIVE、主记录或 strict 文档链路。
- 完成验证：`verification-before-completion`，验证结果写入最终摘要、ACTIVE、主记录或 strict 的 ACC。
- 代码审查：`requesting-code-review`，审查结论写入最终摘要、ACTIVE、主记录或 strict 的 ACC。

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
- standard：结论写入 ACTIVE；复杂或高风险时写入 TASK 或 BUG 主记录。
- strict：结论写入 PRD / REQ / TASK / BUG / ACC / ADR 中的对应位置。
