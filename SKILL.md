---
name: dev-workflow
description: "Lightweight traceable dev workflow for project init, PRD/REQ docs, TDD, bug/feature/refactor records, and human review before commit. Triggers: /dev-workflow, PRD, feature, bug, refactor."
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

- 默认不自动 commit；只有用户明确说“批准提交”或“确认提交”才提交，细节见 `references/details.md`。
- PRD、新功能、现有功能改版、产品文档类任务必须走 `strict`；REQ 未确认前不编码。
- `quick` 默认无正式文档，`standard` 默认一个主记录，`strict` 才拆完整链路。
- `docs/**/TEMPLATE.md` 是母版，日常任务禁止直接修改；新文档用 `TYPE-YYYYMMDD-HHMMSS-XXXX-short-title.md`。
- 默认不在聊天中展开完整文档内容；只列文件路径、追踪编号、验证结果和待人工审核事项。

## Flow Level

- `quick`：文案、样式、小配置、单文件无业务逻辑改动；默认只写最终摘要。
- `standard`：普通 Bug、普通功能调整、单模块功能；默认一个 `TASK` 或 `BUG` 主记录。
- `strict`：PRD、改版、多模块、高风险、接口/数据/权限/支付/订单/登录/部署变化；使用完整链路。

优先级：硬门禁 > 风险自动升级 > 用户指定 > 默认判断。完整定义见 `references/flow.md`。

## Context Budget

默认只读 `AGENTS.md` / `docs/workflow.md` / `scripts/search-dev-docs.sh` 候选；细节见 `references/flow.md`。

## PRD / TDD / Session

- PRD / 改版编码前必须先建 REQ 并等待确认；TDD、代码审查和人工审核细节见 `references/details.md`。
- 长任务可用 `.dev-workflow/session/*-working.json` 保存结构化状态；清理规则见 `references/details.md`。

## References

按需读取：

- `references/flow.md`：流程分级、自动升级、上下文预算、本地索引、archive、写入策略。
- `references/details.md`：项目接入、REQ、TDD、代码审查、人工审核、session、Superpowers / subagent。

## Final Response

- `quick`：流程级别和原因、代码变更、验证结果、待提交文件。
- `standard`：在 quick 基础上加文档同步、代码审查、待人工审核事项。
- `strict`：完整列出流程级别、代码变更、验证结果、文档同步、代码审查、待人工审核、待提交文件、提交状态、未完成事项。
