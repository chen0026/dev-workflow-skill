---
name: dev-workflow
description: "Use when users ask /dev-workflow, project init/check/version, PRD/requirements, feature/bug/refactor tasks, active handoff/history traceability, TDD quality, or real verification before review/commit."
---

# Dev Workflow

Harness-first 的轻量开发工作流。用户不需要记流程命令；开发任务先让 harness 给出护栏，再执行实现、验证和人工审核。

## Natural Language Entry

当用户提出 Bug、功能、重构、维护、PRD、改版或需求类任务时，自动运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" run "用户任务描述"
```

按输出的 `flow / docs_allowed / pre_code_gate / code_allowed / loop_phase / loop_next_decision / next_action` 执行；不要要求用户手动选择 quick/standard/strict。若 `code_allowed: false`，只允许起草或更新门禁文档，等待用户确认后再编码。

完成前运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" verify "用户任务描述"
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" check
```

## Maintenance Commands

- `/dev-workflow init`：初始化项目结构。
- `/dev-workflow init --hooks`：初始化并启用 Git hooks。
- `/dev-workflow init --with-templates`：初始化并复制模板；默认不复制模板。
- `/dev-workflow init --with-scripts`：初始化并复制脚本到项目；默认不复制脚本。
- `/dev-workflow check`：运行项目检查。
- `/dev-workflow version`：输出 skill 版本。
- `/dev-workflow doctor`：运行已安装 skill 的 `doctor`，检查当前项目 harness 版本、目录、hooks、索引和升级建议。
- `/dev-workflow clean-templates`：预览并按确认清理项目内模板副本。
- `/dev-workflow clean-scripts`：预览并按确认清理项目内 dev-workflow 脚本副本。
- `/dev-workflow active list/start/match/finish`：查看、创建、匹配或折叠进行中的 ACTIVE。
- `/dev-workflow loop start/step/verify/decide/status`：在 ACTIVE 内执行验收驱动短闭环。

项目脚本缺失时使用：

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/init-dev-workflow.sh"
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/dev-workflow-harness.sh" doctor
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/dev-workflow-harness.sh" run "用户任务描述"
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/active-work.sh" list
```

## Gates

- 默认不自动 commit；只有用户明确说“批准提交”或“确认提交”才提交。
- `standard` 任务默认先确认一个 `ACTIVE` 交接文件；复杂或高风险才升级 `TASK` / `BUG`。`strict` 任务必须先确认 `REQ`。确认标记统一为 `编码前确认：已确认`。
- `standard / strict` 编码前必须确认测试用例清单。确认标记统一为 `测试用例确认：已确认`；用例必须从 ACTIVE / REQ / BUG 行为倒推，包含前置状态、操作、期望结果、真实验证路径和 RED 失败记录。
- 进行中任务使用 `docs/active/ACTIVE-*.md`；完成后把 8 行以内摘要折叠到 `docs/history/<module>.md`，再清理 ACTIVE。不要使用全局 `current-work.md`。
- 多个 ACTIVE 同时存在时，先用 `active-work.sh match 关键词` 锁定唯一文件；返回 `ambiguous_active` 时必须停止并让用户确认，不得按模块名、最近时间或猜测读取/回填 ACTIVE。
- `code_allowed: false` 时，不创建或修改业务代码；只能准备文档草案、测试计划和待确认问题。
- harness 只检查完整性；需求是否一致必须进入人工审核，不能由脚本直接判定通过。
- 最终验收必须有真实后端、真实接口、真实运行环境或人工实测证据；mock、mock 数据、Playwright route mock 只能做开发辅助或补充测试，不能作为最终验收或降级验收证据。
- 大需求使用自适应 loop：先理解和切片，再按单个可验证 slice 小步实现；不要套固定业务分类。
- standard / strict 进入编码后，每轮使用 `loop-work.sh step -> verify -> decide`；`continue / retry / rescope` 前必须有真实验证证据，`wait_human / stop` 后不得继续编码。
- 新增或修改关键业务代码时默认写简短中文注释，说明职责、业务原因、边界或需求关联；禁止逐行翻译代码。
- 默认不展开完整文档内容，只列文件路径、追踪编号、验证结果和待审核事项。

## Flow Semantics

- `quick`：低风险改动，默认新增文档 0 个，最终摘要即可。
- `standard`：普通 Bug / 功能 / 维护，编码前默认确认一个 `ACTIVE` 和测试用例清单；复杂或高风险才用 `TASK` / `BUG`。
- `strict`：PRD / 改版 / 多模块 / 高风险 / 接口、数据、权限、支付、订单、登录、部署变化，编码前先确认 REQ 和测试用例矩阵。

完整分级、文档预算、命名和索引规则见 `references/flow.md`。

## Requirement Match

需求一致性按 `PRD -> REQ -> ACTIVE/TASK/BUG -> 测试用例清单 -> 真实验证证据 -> 人工审核 -> history -> 提交` 闭环执行。`verify` 输出 `test_case_status` 或 `verification_source_status` 阻断时，必须先补测试清单或真实验证证据。

## Diagnostics

如果项目脚本可能过期、hooks 不确定、或初始化状态不明，运行已安装 skill 的 `doctor`。重点看 `upgrade_needed / missing_required / doctor_status / next_action`。

## References

按需读取：

- `references/flow.md`：流程分级、自动升级、上下文预算、本地索引、archive、写入策略。
- `references/details.md`：项目接入、REQ、Adaptive Loop、TDD、代码审查、人工审核、session、Superpowers / subagent。

## Final Response

- `quick`：流程级别和原因、代码变更、验证结果、待提交文件。
- `standard`：在 quick 基础上加文档同步、代码审查、待人工审核事项。
- `strict`：完整列出流程级别、代码变更、验证结果、文档同步、代码审查、待人工审核、待提交文件、提交状态、未完成事项。
