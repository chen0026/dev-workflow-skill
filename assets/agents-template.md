# AGENTS.md

## 开发工作流强约束

所有新功能、Bug 修复、重构、维护任务必须遵守 `docs/workflow.md`。

## 文档查找优先级

处理需求、开发、修复、维护前，按以下顺序查找上下文：

1. `AGENTS.md`
2. `docs/workflow.md`
3. `scripts/search-dev-docs.sh` 的候选结果，或 `.dev-workflow/index/docs.jsonl`
4. 当前任务关联的 `PRD / REQ / TASK / BUG / ADR / ACC`
5. `docs/design/` 和 `docs/ops/`
6. `docs/legacy/`
7. `docs/archive/`
8. 代码和测试

如果当前代码与 `docs/archive/` 中的旧文档冲突，以当前代码和当前链路文档为准。`docs/archive/` 只作为历史参考，不作为当前实现依据。

## 文档读取预算

默认只读取：

- `AGENTS.md`
- `docs/workflow.md`
- `scripts/search-dev-docs.sh` 的候选结果，或 `.dev-workflow/index/docs.jsonl` 中的少量匹配行
- 用户当前提供的 PRD / 需求 / Bug 描述
- 与当前任务直接相关的文档

默认禁止全量读取 `docs/archive/**`、全部 PRD、全部 REQ、全部 TASK、全部 BUG、全部 ACC、全部 ADR。必须先根据本地索引、当前任务关键词、模块名、功能名、编号筛选候选文档；候选过多时，先列候选和选择依据。

## 文档同步门禁

完成代码变更前，必须同步更新对应文档：

- quick：默认不创建正式文档，只在最终回复写摘要；必要时一个 TASK。
- standard Bug：默认一个 BUG 主记录，验证、审查、验收结论写在同一文档。
- standard 功能 / 维护：默认一个 TASK 主记录，验证、审查、验收结论写在同一文档。
- strict：PRD / 改版使用 PRD + REQ + TASK + ACC，高风险 Bug 可使用 BUG + TASK + ACC。
- 已有项目历史：只在当前变更需要时补 LEGACY 或补录 ADR。

完成前必须执行文档同步检查：

- TASK 是否记录实际改动范围、验证方式和结果。
- PRD / 改版任务是否已建立并确认 REQ 需求追踪矩阵。
- TASK 或 BUG 是否记录代码审查结论。
- BUG 是否记录复现、根因、修复方案和验证结果。
- PRD 是否追加需求变更记录。
- ADR / design / ops 是否已按影响范围更新。
- strict 或复杂验收才要求 ACC 记录验收标准、验证结果和结论。
- 本地索引是否已重建或可重建。

验证和文档同步通过后，必须先进入提交前人工审核，列出待审核内容和待提交文件。只有用户明确回复“批准提交”或“确认提交”后，才能提交一个只包含本次任务相关代码和文档的聚焦 commit，并在提交后列出 commit hash。

没有完成文档同步和人工审核，不得声明任务最终完成；未经用户批准，不得提交代码。

## Git hooks 门禁

项目建议启用 `.githooks`：

- `pre-commit`：默认检查文档结构并重建索引。
- `commit-msg`：提交信息建议包含追踪编号；quick 可使用 `[quick]`。

默认不强制每次代码变更都伴随 `docs/`。正式项目如需强门禁，可在提交环境设置 `DEV_WORKFLOW_REQUIRE_DOCS=1`。

新文档追踪编号统一使用 `TYPE-YYYYMMDD-HHMMSS-XXXX-short-title.md`，旧项目中的 `TASK-0001` 这类编号继续有效。

`docs/**/TEMPLATE.md` 是母版。日常任务只能复制模板创建新文档，禁止直接填写或修改 `TEMPLATE.md`；只有明确要求修改模板时例外。

PRD、新功能、现有功能改版或产品文档类任务，必须先建立 REQ 需求追踪矩阵并等待人工确认；未确认前不得编码。实现阶段优先 TDD，测试或验收项必须关联 REQ / BUG。

流程强度默认从 `quick` 起步。优先级：硬门禁 > 风险自动升级 > 文档预算 > 用户指定 > 默认 quick。用户指定 `quick` 但出现 PRD、改版、接口、数据、核心链路等风险时，必须自动升级并说明原因；任务不确定但未发现明确风险时仍用 `quick`。

文档预算：quick 新增文档 0 个；standard 新增文档最多 1 个；strict 才允许完整链路。普通任务禁止同时新建 `TASK + BUG + ACC`，不得为完成任务手工更新 `docs/index.md`。

长任务可使用 `.dev-workflow/session/*-working.json` 保存结构化状态，减少上下文占用。完成后确认已合并到主记录或 strict 文档链路，再清理并在最终回复中列出。

`.dev-workflow/index/` 是可重建的本地机器索引，默认不提交。`docs/index.md` 只作为人类入口说明，不再作为每次任务必须手工更新的共享索引。

hooks 只做最低限度拦截，不能替代 PRD、TASK、BUG、ADR、ACC 的内容质量检查。

## 代码审查规则

代码审查是完成前门禁。小任务执行自查；复杂、高风险或影响范围较大的任务使用 subagent 或人工独立 review。审查结论回填到主记录；quick 可只在最终回复列出。

## Subagent 使用规则

默认不使用 subagent。仅在任务涉及多个独立模块、Bug 根因不明确、需要并行调查、影响范围较大、或完成前需要独立 review / QA 时使用。

subagent 的调研结论、根因证据、验收结果、被否决方案必须回填到主记录或 strict 文档链路。
