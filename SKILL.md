---
name: dev-workflow
description: "Use when users ask /dev-workflow, project init/check/version, PRD or requirements work, feature/bug/refactor/maintenance tasks, traceable development, or real verification before review/commit."
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

项目脚本缺失时使用：

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/init-dev-workflow.sh"
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/dev-workflow-harness.sh" doctor
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/dev-workflow-harness.sh" run "用户任务描述"
```

## Gates

- 默认不自动 commit；只有用户明确说“批准提交”或“确认提交”才提交。
- `standard` 任务必须先确认一个 `TASK` 或 `BUG` 主记录；`strict` 任务必须先确认 `REQ`。确认标记统一为 `编码前确认：已确认`。
- `code_allowed: false` 时，不创建或修改业务代码；只能准备文档草案、测试计划和待确认问题。
- harness 只检查完整性；需求是否一致必须进入人工审核，不能由脚本直接判定通过。
- 最终验收必须有真实后端、真实接口、真实运行环境或人工实测证据；mock、mock 数据、Playwright route mock 只能做开发辅助或补充测试，不能作为最终验收或降级验收证据。
- 大需求使用自适应 loop：先理解和切片，再按单个可验证 slice 小步实现；不要套固定业务分类。
- 默认不展开完整文档内容，只列文件路径、追踪编号、验证结果和待审核事项。

## Flow Semantics

- `quick`：低风险改动，默认新增文档 0 个，最终摘要即可。
- `standard`：普通 Bug / 功能 / 维护，编码前先确认一个 `TASK` 或 `BUG` 主记录。
- `strict`：PRD / 改版 / 多模块 / 高风险 / 接口、数据、权限、支付、订单、登录、部署变化，编码前先确认 REQ。

完整分级、文档预算、命名和索引规则见 `references/flow.md`。

## Requirement Match

需求一致性按 `PRD -> REQ -> TASK/BUG -> 真实验证证据 -> 人工审核 -> 提交` 闭环执行。`verify` 输出 `requirement_match: pending-human-review` 时，列出证据和缺口，等待用户确认；若输出 `verification_source_status: mock_only_final_evidence`，必须补真实验证后再审核。

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
