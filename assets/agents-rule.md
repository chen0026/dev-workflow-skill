# AGENTS.md 建议规则

## 开发工作流强约束

所有新功能、Bug 修复、重构、维护任务必须遵守 `docs/workflow.md`。

## 文档查找优先级

处理需求、开发、修复、维护前，按以下顺序查找上下文：

1. `AGENTS.md`
2. `docs/workflow.md`
3. `docs/index.md`
4. 当前任务关联的 `PRD / TASK / BUG / ADR / ACC`
5. `docs/design/` 和 `docs/ops/`
6. `docs/legacy/`
7. `docs/archive/`
8. 代码和测试

如果当前代码与 `docs/archive/` 中的旧文档冲突，以当前代码和当前链路文档为准。`docs/archive/` 只作为历史参考，不作为当前实现依据。

完成代码变更前，必须同步更新对应文档：

- 新功能：PRD + TASK + ACC，必要时 ADR / design / ops。
- Bug 修复：BUG + TASK + ACC，必要时 ADR / design / ops。
- 重构 / 维护：TASK + ACC，必要时 ADR / design / ops。
- 已有项目历史：只在当前变更需要时补 LEGACY 或补录 ADR。

完成前必须执行文档同步检查：

- TASK 是否记录实际改动范围、验证方式和结果。
- TASK 或 ACC 是否记录代码审查结论。
- BUG 是否记录复现、根因、修复方案和验证结果。
- PRD 是否追加需求变更记录。
- ADR / design / ops 是否已按影响范围更新。
- ACC 是否记录验收标准、验证结果和结论。
- `docs/index.md` 是否已更新。

验证和文档同步通过后，必须提交一个只包含本次任务相关代码和文档的聚焦 commit，并在最终回复中列出 commit hash。

没有完成文档同步和提交，不得声明任务完成。

## Git hooks 门禁

项目建议启用 `.githooks`：

- `pre-commit`：代码变更必须伴随 `docs/` 或 `AGENTS.md` 变更。
- `commit-msg`：提交信息必须包含追踪编号，例如 `TASK-0001` 或 `BUG-0001`。

hooks 只做最低限度拦截，不能替代 PRD、TASK、BUG、ADR、ACC 的内容质量检查。

## 代码审查规则

代码审查是完成前门禁。小任务执行自查；复杂、高风险或影响范围较大的任务使用 subagent 或人工独立 review。审查结论必须回填到 TASK 或 ACC。

## Subagent 使用规则

默认不使用 subagent。仅在任务涉及多个独立模块、Bug 根因不明确、需要并行调查、影响范围较大、或完成前需要独立 review / QA 时使用。

subagent 的调研结论、根因证据、验收结果、被否决方案必须回填到 TASK / BUG / ACC / ADR。
