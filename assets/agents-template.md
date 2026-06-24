# AGENTS.md

## Dev Workflow

所有新功能、Bug 修复、重构、维护、PRD、改版和需求类任务必须遵守 `docs/workflow.md`。

## Harness-first

开发任务不要求用户记命令。收到自然语言任务后，先运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" run "用户任务描述"
```

按输出的 `flow / docs_allowed / pre_code_gate / code_allowed / loop_phase / loop_next_decision / next_action` 执行。`code_allowed: false` 时，只能准备门禁文档，等待人工确认。完成前运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" verify "用户任务描述"
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" check
```

`verify` 只检查完整性；需求是否一致必须等待人工审核确认。

## Hard Gates

- 默认不自动提交代码；只有用户明确回复“批准提交”或“确认提交”后才能 commit。
- quick 默认新增文档 0 个；standard 编码前默认先确认一个 ACTIVE，复杂或高风险才使用 TASK / BUG；strict 编码前必须先确认 REQ。
- 编码前确认标记统一为 `编码前确认：已确认`；没有该标记不得修改业务代码。
- standard / strict 编码前必须确认测试用例清单，标记为 `测试用例确认：已确认`；用例必须从 ACTIVE / REQ / BUG 行为倒推，包含前置状态、操作、期望结果、真实验证路径和 RED 失败记录。
- standard 进行中任务使用 `docs/active/ACTIVE-*.md`；完成并通过人工审核后，把 8 行以内摘要折叠到 `docs/history/<module>.md`，再清理 ACTIVE。
- 多个 ACTIVE 同时存在时，必须先用 `active-work.sh match 关键词` 锁定唯一文件；返回 `ambiguous_active` 时停止并让用户确认，禁止按模块名、最近时间或猜测选择。
- 大需求使用 Adaptive Loop：先按需求文档结构、代码边界、风险点和可验证粒度切片，不套固定业务分类。
- standard / strict 进入编码后，每轮用 `loop-work.sh step -> verify -> decide`；`continue / retry / rescope` 前必须有真实验证证据，`wait_human / stop` 后不得继续编码。
- 最终验收必须使用真实后端、真实接口、真实运行环境、本地联调、测试环境或人工实测证据；mock 数据、Playwright route mock、接口拦截、fixture、stub、MSW 只能做辅助测试，不能作为最终验收或降级验收。
- 普通任务禁止同时新建 `TASK + BUG + ACC`。
- 不手工维护或提交 `docs/index.md`；使用 `.dev-workflow/index/docs.jsonl` 本地索引。
- `docs/**/TEMPLATE.md` 是母版，日常任务禁止直接修改。

## Context Budget

默认只读：

1. `AGENTS.md`
2. `docs/workflow.md`
3. skill 脚本 `search-dev-docs.sh` 的候选结果或 `.dev-workflow/index/docs.jsonl`
4. 用户当前提供的 PRD / 需求 / Bug 描述
5. 用 `active-work.sh match 关键词` 锁定的唯一 ACTIVE；未锁定或多候选时不得读取候选内容
6. `docs/history/<module>.md` 的最近相关条目
7. 当前任务直接相关的文档、代码和测试

默认不全量读取 `docs/archive/**`、全部 PRD、全部 REQ、全部 TASK、全部 BUG、全部 ACC、全部 ADR。

## Flow Meaning

- quick：低风险改动，最终回复摘要即可。
- standard：普通 Bug / 功能 / 维护，默认先确认一个 `ACTIVE`；复杂或高风险才使用 `TASK` / `BUG`。
- strict：PRD / 改版 / 多模块 / 高风险 / 接口、数据、权限、支付、订单、登录、部署变化，先确认 REQ。

## Requirement Match

需求一致性按 `PRD -> REQ -> ACTIVE/TASK/BUG -> 测试用例清单 -> 真实验证证据 -> 人工审核 -> history -> 提交` 闭环执行。最终回复必须列出测试覆盖、真实验证证据、待审核内容和待提交文件。

## Git Hooks

`.githooks` 是可选项目门禁。正式项目建议启用：

```bash
git config core.hooksPath .githooks
```

hooks 只做最低限度拦截，不能替代需求确认、代码审查和人工审核。
