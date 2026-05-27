---
name: dev-workflow
description: Use this skill when development should follow a lightweight traceable workflow: requirements, tasks, bug fixes, design decisions, acceptance, documentation sync, and final git commit. Trigger for prompts like "/dev-workflow init", "/dev-workflow init --hooks", "/dev-workflow check", "/dev-workflow 初始化项目", "/dev-workflow 接入项目", "/dev-workflow 启用 hooks", new features, bug fixes, refactors, maintenance, PRD/task planning, acceptance checks, docs workflow setup, or requests to prevent code changes from drifting away from requirements.
---

# Dev Workflow

目标：用最少文档建立开发追踪链路，不让流程成为开发阻碍。

## 快捷用法

用户可以直接输入：

```text
/dev-workflow 初始化项目
/dev-workflow 接入项目
/dev-workflow 初始化项目并启用 hooks
/dev-workflow 检查文档
/dev-workflow init
/dev-workflow init --hooks
/dev-workflow check
/dev-workflow 修复这个 Bug：...
/dev-workflow 开发这个功能：...
```

对应行为：

- `初始化项目` / `接入项目`：运行 `scripts/init-dev-workflow.sh`，检查并补齐 `AGENTS.md`、`docs/`、`scripts/`、`.githooks/`。
- `init` / `初始化项目` / `接入项目`：运行 `scripts/init-dev-workflow.sh`，检查并补齐 `AGENTS.md`、`docs/`、`scripts/`、`.githooks/`。
- `init --hooks` / `初始化项目并启用 hooks` / `启用 hooks`：运行 `scripts/init-dev-workflow.sh --enable-hooks`。
- `check` / `检查文档`：运行 `scripts/check-dev-docs.sh`。
- `开发 / 修复 / 维护`：按本 workflow 执行完整任务闭环。

如果项目内还没有脚本，使用本 Skill 自带脚本：

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/init-dev-workflow.sh"
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/check-dev-docs.sh"
```

## 默认闭环

- 新功能：`PRD + TASK + ACC`
- Bug 修复：`BUG + TASK + ACC`
- 维护 / 重构：`TASK + ACC`
- 按需补充：`ADR / design / ops / LEGACY`

## 使用前接入检查

执行本 Skill 前先检查当前项目：

1. 是否存在 `AGENTS.md`。
2. 是否存在 `docs/`。
3. `docs/` 是否已有旧文档。
4. 是否已有 `docs/workflow.md`、`docs/index.md` 和必要子目录。

处理规则：

- 没有 `AGENTS.md`：创建，并写入 dev-workflow 规则和文档查找优先级。
- 已有 `AGENTS.md`：保留原内容，只追加 dev-workflow 规则；如已有同类规则，先更新，不重复堆叠。
- 没有 `docs/`：创建标准目录骨架。
- 已有 `docs/` 但不是 dev-workflow 结构：把旧文档移动到 `docs/archive/legacy-docs-YYYYMMDD/`，再创建新结构。
- 已有 dev-workflow 结构：沿用，不覆盖已有文档。
- 归档旧文档前，先确认这些文件属于文档资料；不要移动代码、配置、脚本或构建产物。

`AGENTS.md` 中必须写明文档查找优先级：

1. `AGENTS.md`
2. `docs/workflow.md`
3. `docs/index.md`
4. 当前任务关联的 `PRD / TASK / BUG / ADR / ACC`
5. `docs/design/` 和 `docs/ops/`
6. `docs/legacy/`
7. `docs/archive/`
8. 代码和测试

如果当前代码与旧归档文档冲突，以当前代码和当前链路文档为准；`docs/archive/` 只作为历史参考。

## 什么时候补充文档

只在满足条件时补：

- ADR：架构、接口契约、数据模型、技术选型、重要取舍、历史设计问题。
- design：当前架构说明已经变化，或未来维护必须理解新结构。
- ops：部署、配置、监控、告警、回滚、应急步骤变化。
- LEGACY：已有项目中，当前任务必须理解历史但没有文档。

## 执行顺序

1. 执行项目接入检查。
2. 判断任务类型。
3. 建立最小追踪文档。
4. 编码或修复。
5. 验证结果。
6. 执行代码审查。
7. 回填 TASK / BUG / ACC 的实际事实。
8. 更新 `docs/index.md`。
9. 提交本次相关代码和文档。

可用脚本：

- `scripts/init-dev-workflow.sh`：初始化项目工作流。
- `scripts/check-dev-docs.sh`：完成前检查文档结构和追踪链路。

## 完成前检查

最终回复前必须确认：

- 关联文档已创建或更新。
- TASK 写明实际改动和验证结果。
- TASK 或 ACC 写明代码审查结论。
- ACC 写明验收结论。
- ADR / design / ops 已处理，或明确不需要。
- `docs/index.md` 已更新。
- 已提交聚焦 commit。

如果项目存在 `scripts/check-dev-docs.sh`，最终回复前运行它。

没有完成文档同步和提交，不声明任务完成。

## 提交规则

- 只提交本次任务相关文件。
- 避开用户已有的无关改动。
- commit message 引用主编号。
- 如果项目启用了 `.githooks`，必须确保 hooks 通过。

## 代码审查规则

代码审查是完成前门禁，但保持轻量：

- 小任务：执行自查，重点看需求偏离、无关改动、错误处理、测试缺口、文档同步。
- 复杂 / 高风险任务：使用 subagent 或人工做独立 review。
- 审查发现的问题必须先修复，或记录为遗留问题并关联后续 TASK。
- 审查结论必须回填到 TASK 或 ACC。

## 与 Superpowers 配合

如果当前环境有 Superpowers，可以按阶段配合使用：

- 需求澄清：`brainstorming`，结论写入 PRD / TASK。
- 计划制定：`writing-plans`，任务拆解写入 TASK。
- Bug 定位：`systematic-debugging`，复现、路径、根因写入 BUG。
- 实现：`test-driven-development`，验证方式写入 TASK / ACC。
- 并行执行：`subagent-driven-development`，各 subagent 结论写入 TASK / BUG / ADR / ACC。
- 完成验证：`verification-before-completion`，验证结果写入 ACC。
- 代码审查：`requesting-code-review`，审查结论写入 TASK / ACC。

dev-workflow 不替代 Superpowers，只负责建立追踪链路、沉淀关键结论、完成前检查文档和提交。

## Subagent 使用规则

默认不使用 subagent。满足以下任一条件时才使用：

- 任务涉及多个独立模块。
- Bug 根因不明确。
- 需要并行调查代码路径、测试、文档或影响范围。
- 改动影响范围较大。
- 完成前需要独立 review 或 QA 检查。

subagent 输出必须沉淀到文档：

- 调研结论写入 TASK。
- 根因证据写入 BUG。
- 验收结果写入 ACC。
- 被否决方案写入 TASK 或 ADR。

示例：

```text
TASK-0001 implement login api
BUG-0001 fix token refresh failure
PRD-0001 add user login workflow
```

## 最终回复

用简体中文简短列出：

- 代码变更
- 验证结果
- 文档同步
- 提交记录
- 未完成事项

## 可选硬门禁

项目可以启用轻量 Git hooks：

- `pre-commit`：代码变更必须伴随 `docs/` 或 `AGENTS.md` 变更。
- `commit-msg`：提交信息必须包含追踪编号。

hooks 只做最低限度检查，不推断业务语义；具体文档质量仍由本 workflow 和验收记录保证。

默认只提供 hooks 模板，不自动启用。只有用户明确要求启用，或项目被明确标记为正式接入 dev-workflow，才执行：

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit .githooks/commit-msg scripts/check-dev-workflow.sh
```

关闭：

```bash
git config --unset core.hooksPath
```
