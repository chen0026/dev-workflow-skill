---
name: dev-workflow
description: "Use when users ask /dev-workflow, project init/check/version, PRD or requirements work, feature/bug/refactor/maintenance tasks, or traceable development with review before commit."
---

# Dev Workflow

Harness-first 的轻量开发工作流。用户不需要记流程命令；开发任务先让 harness 给出护栏，再执行实现、验证和人工审核。

## Natural Language Entry

当用户提出 Bug、功能、重构、维护、PRD、改版或需求类任务时，自动运行：

```bash
scripts/dev-workflow-harness.sh run "用户任务描述"
```

如果项目内没有脚本，使用已安装 skill 的同名脚本。按输出的 `flow / docs_allowed / next_action` 执行；不要要求用户手动选择 quick/standard/strict。

完成前运行：

```bash
scripts/dev-workflow-harness.sh verify "用户任务描述"
scripts/dev-workflow-harness.sh check
```

## Maintenance Commands

- `/dev-workflow init`：初始化项目结构。
- `/dev-workflow init --hooks`：初始化并启用 Git hooks。
- `/dev-workflow init --with-templates`：初始化并复制模板；默认不复制模板。
- `/dev-workflow check`：运行项目检查。
- `/dev-workflow version`：输出 skill 版本。
- `/dev-workflow clean-templates`：预览并按确认清理项目内模板副本。

项目脚本缺失时使用：

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/init-dev-workflow.sh"
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/dev-workflow-harness.sh" run "用户任务描述"
```

## Gates

- 默认不自动 commit；只有用户明确说“批准提交”或“确认提交”才提交。
- PRD、产品文档、新功能改版等 `strict` 任务，REQ 未经人工确认前不编码。
- harness 只检查完整性；需求是否一致必须进入人工审核，不能由脚本直接判定通过。
- 默认不展开完整文档内容，只列文件路径、追踪编号、验证结果和待审核事项。

## Flow Semantics

- `quick`：低风险改动，默认新增文档 0 个，最终摘要即可。
- `standard`：普通 Bug / 功能 / 维护，最多一个 `TASK` 或 `BUG` 主记录。
- `strict`：PRD / 改版 / 多模块 / 高风险 / 接口、数据、权限、支付、订单、登录、部署变化，先确认 REQ。

完整分级、文档预算、命名和索引规则见 `references/flow.md`。

## Requirement Match

需求一致性按 `PRD -> REQ -> TASK/BUG -> 验证证据 -> 人工审核 -> 提交` 闭环执行。`verify` 输出 `requirement_match: pending-human-review` 时，列出证据和缺口，等待用户确认。

## References

按需读取：

- `references/flow.md`：流程分级、自动升级、上下文预算、本地索引、archive、写入策略。
- `references/details.md`：项目接入、REQ、TDD、代码审查、人工审核、session、Superpowers / subagent。

## Final Response

- `quick`：流程级别和原因、代码变更、验证结果、待提交文件。
- `standard`：在 quick 基础上加文档同步、代码审查、待人工审核事项。
- `strict`：完整列出流程级别、代码变更、验证结果、文档同步、代码审查、待人工审核、待提交文件、提交状态、未完成事项。
