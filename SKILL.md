---
name: dev-workflow
description: "Use this skill for lightweight traceable development: project init, docs workflow, PRD/REQ traceability, TDD, bug fixes, acceptance, human review before commit, and optional approved git commit. Triggers: /dev-workflow init, /dev-workflow init --hooks, /dev-workflow check, /dev-workflow clean-templates, PRD implementation, feature work, bug fix, refactor, maintenance, or requests to prevent code from drifting away from requirements."
---

# Dev Workflow

用最少文档建立开发追踪链路，避免实现偏离需求。

## Commands

- `/dev-workflow init`：运行 `scripts/init-dev-workflow.sh`，补齐 `AGENTS.md`、`docs/`、`scripts/`、`.githooks/`。
- `/dev-workflow init --hooks`：初始化并启用 Git hooks。
- `/dev-workflow init --with-templates`：初始化并把模板复制进项目。默认不复制模板。
- `/dev-workflow check`：运行 `scripts/check-dev-docs.sh`。
- `/dev-workflow clean-templates`：预览项目内 `docs/**/TEMPLATE.md`；确认后运行 `scripts/clean-templates.sh --apply`。

项目内没有脚本时，使用 Skill 自带脚本：

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/init-dev-workflow.sh"
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/check-dev-docs.sh"
```

## Hard Rules

- 默认不自动 commit。完成后进入人工审核；只有用户明确说“批准提交”或“确认提交”才提交。
- PRD、新功能、现有功能改版、产品文档类任务必须走 `strict`：先建立 `REQ` 需求追踪矩阵，人工确认后再编码。
- 新功能、PRD 改版、Bug 修复优先 TDD；无法自动化时，记录原因并写手工验收项。
- `docs/**/TEMPLATE.md` 是母版，日常任务禁止直接修改；用 `scripts/new-doc.sh TYPE short-title` 创建新文档。
- 新文档使用 `TYPE-YYYYMMDD-HHMMSS-XXXX-short-title.md`，例如 `TASK-20260529-101500-a1b2-login-api.md`。
- 默认禁止全量读取历史文档；先读 `AGENTS.md`、`docs/workflow.md`、`docs/index.md`，再按关联读取少量文档。
- 完成前必须验证、代码审查、文档同步、更新 `docs/index.md`，并列出待人工审核内容和待提交文件。

## Auto Flow Level

自动选择流程强度，不要求用户手动指定：

- `quick`：文案、样式、小配置、单文件无业务逻辑改动。少读历史，完成前做最小记录。
- `standard`：普通 Bug、普通功能调整、单模块功能。使用 `TASK/BUG + ACC`，验证和代码审查。
- `strict`：PRD、产品文档、现有功能改版、多模块、高风险、接口/数据/权限/支付/订单/登录/部署变化。必须 `PRD + REQ + TASK + ACC`。

优先级：硬门禁 > 风险自动升级 > 用户指定 > 默认判断。

如果用户指定 `quick` 但出现 PRD、改版、接口、数据、核心链路等风险，必须自动升级并说明原因。如果任务类型不确定，默认 `standard`，不要用 `quick`。

详细分级见 `references/flow-levels.md`。

## Session State

- `quick` 默认不用 session 状态文件。
- `standard` 超过一轮、涉及多个文件、或上下文可能变长时，使用 `.dev-workflow/session/*-working.json`。
- `strict` 默认使用 session 状态文件；REQ 是正式文档，不清理。
- session 文件只存结构化摘要、路径和结论，不存完整 PRD 或大段代码。
- 完成后，确认内容已合并到 TASK / BUG / ACC，再清理 session，并在最终回复列出。

脚本：`scripts/session-state.sh create|list|clean [--apply]`。详见 `references/workflow-details.md`。

## Context Budget

默认只读：

- `AGENTS.md`
- `docs/workflow.md`
- `docs/index.md`
- 用户当前提供的 PRD / 需求 / Bug 描述
- 与当前任务直接相关的文档

不要默认读取 `docs/archive/**` 或全部历史 PRD/TASK/BUG/ACC。候选文档过多时，先列候选和选择依据。

详细规则见 `references/context-budget.md`。

## PRD / TDD Gate

PRD / 改版类任务编码前必须：

1. 创建或更新 `REQ` 需求追踪矩阵。
2. 每个 REQ 保留 PRD 原文依据、当前实现、目标行为、验收方式和测试计划。
3. 等待人工确认 REQ。

REQ 未确认前，不创建实现代码，不修改业务代码。

详细规则见 `references/workflow-details.md`。

## References

按需读取：

- `references/workflow-details.md`：项目接入、命名、REQ、TDD、代码审查、人工审核细节。
- `references/context-budget.md`：文档读取预算，避免全量读取历史。
- `references/flow-levels.md`：quick / standard / strict 自动分级和升级规则。
- `references/superpowers.md`：与 Superpowers、subagent 的配合方式。

## Final Response

用简体中文简短列出：

- 流程级别和原因
- 代码变更
- 验证结果
- 文档同步
- 代码审查
- 待人工审核事项
- 待提交文件
- 提交状态
- 未完成事项
