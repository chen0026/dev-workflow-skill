# Changelog

## 0.10.0 - 2026-06-05

- 将流程改为分级留痕：quick 默认不创建正式文档，standard 默认一个主记录，strict 才拆完整链路。
- standard 的验证、代码审查、验收结论合并写入 TASK 或 BUG，不再默认创建 ACC。
- 放宽 `check-dev-docs.sh`，不再强制 TASK 关联 ACC 或填写 TDD / 验收映射。
- Git hooks 默认不强制代码变更必须伴随 docs；需要强门禁时设置 `DEV_WORKFLOW_REQUIRE_DOCS=1`。
- 最终回复默认只列摘要和文件路径，不展开完整文档内容，减少 token 消耗。

## 0.9.0 - 2026-06-03

- 将 `docs/index.md` 从每次任务必须手工更新的共享索引，改为人类入口说明，减少多分支合并冲突。
- 新增 `.dev-workflow/index/docs.jsonl` 本地机器索引，默认不提交、可随时重建。
- 新增 `scripts/reindex-dev-docs.sh` 和 `scripts/search-dev-docs.sh`，用于重建和检索文档索引。
- 初始化时创建 `.dev-workflow/index/`，并把它加入 `.gitignore`。
- 文档读取规则改为优先检索本地索引，再打开少量相关文档，降低 token 消耗。

## 0.8.0 - 2026-05-29

- 明确自动分级优先级：硬门禁 > 风险自动升级 > 用户指定 > 默认判断。
- 用户指定 `quick` 但检测到高风险时，自动升级并说明原因。
- 新增 `.dev-workflow/session/*-working.json` 长任务状态规则，减少上下文占用。
- 新增 `scripts/session-state.sh` 管理 session 状态文件。

## 0.7.0 - 2026-05-29

- 瘦身 `SKILL.md`，只保留入口、硬门禁、自动分级和文档读取预算。
- 新增 `references/`，按需承载 workflow 细节、上下文预算、流程分级和 Superpowers 配合。
- 增加自动流程分级：`quick / standard / strict`，并支持风险自动升级。
- 增加文档读取预算，默认禁止全量读取历史文档。

## 0.6.1 - 2026-05-29

- 新增 `scripts/clean-templates.sh`，用于清理旧项目中已经复制进去的 `docs/**/TEMPLATE.md`。
- 清理脚本默认只预览，传入 `--apply` 才删除。

## 0.6.0 - 2026-05-29

- 初始化项目时默认不再复制 `docs/**/TEMPLATE.md`。
- `new-doc.sh` 默认从已安装的 dev-workflow Skill 模板创建新文档。
- 新增 `--with-templates` 选项，用于需要项目自包含模板的场景。

## 0.5.0 - 2026-05-29

- 增加 REQ 需求追踪矩阵，约束 PRD / 改版类任务不能直接编码。
- PRD / 改版类任务必须先拆需求项、绑定任务、验收和测试计划，并等待人工确认。
- 增加 TDD 门禁：新功能、PRD 改版、Bug 修复默认优先先写测试或手工验收项。

## 0.4.1 - 2026-05-28

- 增加模板保护规则，禁止日常任务直接修改 `docs/**/TEMPLATE.md`。
- 新增 `scripts/new-doc.sh`，用于从模板创建带时间戳编号的新文档。

## 0.4.0 - 2026-05-28

- 将新文档命名规则改为时间戳编号，避免多电脑、多分支并行时产生序号冲突。
- hooks 和检查脚本兼容新旧追踪编号。
- 新增 `scripts/new-doc-id.sh` 用于生成时间戳文档编号。

## 0.3.0 - 2026-05-28

- 将默认行为改为提交前人工审核。
- 完成开发、验证、代码审查和文档同步后，不再自动 commit。
- 只有用户明确“批准提交”或“确认提交”后，才提交本次相关代码和文档。

## 0.2.2 - 2026-05-28

- 修复 `SKILL.md` frontmatter 中 `description` 未加引号导致 YAML 解析失败的问题。

## 0.2.1 - 2026-05-27

- 增加与 Superpowers 配合的使用说明。

## 0.2.0 - 2026-05-27

- 增加代码审查步骤，作为完成前轻量门禁。
- TASK / ACC 模板增加代码审查记录。
- 文档检查脚本增加 TASK 代码审查记录检查。

## 0.1.0 - 2026-05-27

- 初始化 `dev-workflow` Skill。
- 支持 `/dev-workflow init`、`/dev-workflow init --hooks`、`/dev-workflow check` 日常命令。
- 内置项目接入检查、文档模板、Git hooks、初始化脚本和文档检查脚本。
- 支持新功能、Bug 修复、维护 / 重构的轻量追踪闭环。
