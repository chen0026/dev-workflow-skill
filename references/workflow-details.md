# Workflow Details

## 文档类型

- 新功能 / PRD 改版：`PRD + REQ + TASK + ACC`
- Bug 修复：`BUG + TASK + ACC`
- 维护 / 重构：`TASK + ACC`
- 按需补充：`ADR / design / ops / LEGACY`

## 项目接入

执行前检查：

1. 是否存在 `AGENTS.md`。
2. 是否存在 `docs/`。
3. `docs/` 是否已有旧文档。
4. 是否已有 `docs/workflow.md`、`docs/index.md`、必要子目录和本地索引脚本。

处理规则：

- 没有 `AGENTS.md`：创建，并写入 dev-workflow 规则和文档查找优先级。
- 已有 `AGENTS.md`：保留原内容，只追加 dev-workflow 规则；如已有同类规则，先更新，不重复堆叠。
- 没有 `docs/`：创建标准目录骨架。
- 已有 `docs/` 但不是 dev-workflow 结构：把旧文档移动到 `docs/archive/legacy-docs-YYYYMMDD/`，再创建新结构。
- 已有 dev-workflow 结构：沿用，不覆盖已有文档。
- 归档旧文档前，先确认这些文件属于文档资料；不要移动代码、配置、脚本或构建产物。

## 本地索引

- `.dev-workflow/index/docs.jsonl` 是可重建机器索引，默认不提交。
- 完成文档同步后运行 `scripts/reindex-dev-docs.sh`。
- 查历史文档先用 `scripts/search-dev-docs.sh 关键词`，只打开最相关的少量文档。
- `docs/index.md` 只作为人类入口说明，不作为每次任务必须手工更新的共享索引。

## 命名规则

新文档统一使用：

```text
TYPE-YYYYMMDD-HHMMSS-XXXX-short-title.md
```

- `TYPE`：`PRD / REQ / TASK / BUG / ADR / ACC / OPS / LEGACY`。
- `YYYYMMDD-HHMMSS`：创建文档时的本地时间。
- `XXXX`：4 位小写随机码。
- `short-title`：英文短标题，使用小写和连字符。

项目内如存在 `scripts/new-doc-id.sh`，优先用它生成编号。

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

## TDD

新功能、PRD 改版、Bug 修复默认优先使用 TDD：

- 编码前先写测试或手工验收项。
- 每个测试或验收项必须关联 REQ / BUG。
- 有测试框架时，先确认目标测试失败，再编码让测试通过。
- 已有功能改版时，先记录当前行为，再写 PRD 目标行为测试。
- 没有测试框架或不适合自动化时，必须在 REQ / TASK / ACC 里记录原因，并写手工验收项。

## 代码审查

代码审查是完成前门禁，但保持轻量：

- 小任务：执行自查，重点看需求偏离、无关改动、错误处理、测试缺口、文档同步。
- 复杂 / 高风险任务：使用 subagent 或人工做独立 review。
- 审查发现的问题必须先修复，或记录为遗留问题并关联后续 TASK。
- 审查结论必须回填到 TASK 或 ACC。

## 人工审核和提交

- 默认不自动 commit。
- 完成开发、验证、代码审查、文档同步后，最终回复必须列出待审核内容和待提交文件。
- 只有用户明确回复“批准提交”或“确认提交”后，才执行 commit。
- 如果用户要求调整，先修改并重新验证、审查、同步文档，再回到人工审核。
- 如果用户要求不提交，保留变更并说明当前状态。

## Session 状态文件

为减少长任务占用上下文，可以使用 `.dev-workflow/session/*-working.json`。

默认规则：

- quick：不用 session 状态文件。
- standard：超过一轮、涉及多个文件、或上下文可能变长时使用。
- strict：默认使用 session 状态文件，同时 REQ 作为正式文档先落地。

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

- 完成验证、代码审查、文档同步，并确认 session 内容已合并到 TASK / BUG / ACC 后，可以清理。
- 清理必须在最终回复中列出。
- 如果存在 `open_questions`、文档未同步、或无法确认已合并，不清理，列为未完成事项。

脚本：

```bash
scripts/session-state.sh create TASK-xxx
scripts/session-state.sh list
scripts/session-state.sh clean
scripts/session-state.sh clean --apply
```
