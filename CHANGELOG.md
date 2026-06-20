# Changelog

## 0.23.0 - 2026-06-20

- 新增测试用例质量门禁：`standard / strict` 编码前必须确认测试用例清单，并写入 `测试用例确认：已确认`。
- harness 新增 `test_case_policy / test_case_required_fields / test_case_status` 输出，代码改动缺少测试用例确认或关键字段时阻断。
- 测试用例清单必须从 REQ / BUG 行为倒推，包含关联需求、场景、前置状态、操作、期望结果、测试类型、真实验证路径、mock 使用限制和 RED 失败记录。
- 更新 TASK / BUG / REQ 模板、AGENTS 规则、workflow 和 README，减少测试写偏导致的返工。

## 0.22.0 - 2026-06-20

- 新增真实验证门禁：最终验收必须来自真实后端、真实接口、真实运行环境、本地联调、测试环境或人工实测证据。
- mock 数据、Playwright route mock、接口拦截、fixture、stub、MSW 只能作为开发辅助或补充测试，不能作为最终验收或降级验收。
- harness 新增 `verification_policy / mock_policy / final_evidence_required / verification_source_status` 输出。
- `verify` 检测到代码改动的最终证据只有 mock 时，输出 `verification_source_status: mock_only_final_evidence` 并阻断。
- 更新 SKILL、README、workflow、AGENTS 模板和 TASK / BUG / ACC 模板，要求记录最终验收来源和证据。

## 0.21.0 - 2026-06-20

- harness 新增 `loop_phase / loop_next_decision / max_iterations / stop_condition / slice_strategy` 输出，让复杂需求按短反馈循环推进。
- 新增自适应切片语义：优先按需求文档自身结构、代码边界、风险点和可验证粒度切片，不绑定固定业务分类。
- `verify` 输出 loop 当前阶段和下一步决策：阻断时停止，证据不足时进入验证循环，待人工确认时进入 `human_gate`。
- 更新 SKILL、README、AGENTS 模板和 workflow 文档，强调 Loop engineering 是执行节奏控制，不是新增重文档模板。

## 0.20.0 - 2026-06-20

- harness 新增 `pre_code_gate / pre_code_doc / code_allowed` 输出，`standard` 和 `strict` 默认先停在编码前文档确认阶段。
- `standard` 改为编码前先确认一个 `TASK` 或 `BUG` 主记录，不再允许先编码、完成前才回填文档。
- `strict` 继续要求 `REQ` 编码前确认，并统一使用 `编码前确认：已确认` 作为可检查标记。
- `verify` 增加编码前确认检查：`standard / strict` 已有代码改动但缺少确认标记时，输出 `pre_code_status: missing_pre_code_confirmation` 并阻断。
- 更新 `TASK / BUG / REQ` 模板、AGENTS 规则、workflow 和 README，明确“双人工门禁”：编码前确认文档，提交前确认实现。

## 0.19.0 - 2026-06-11

- `/dev-workflow init` 默认不再复制通用脚本到项目 `scripts/`，只初始化 `AGENTS.md`、`docs/`、`.githooks/`、`.gitignore` 和本地索引目录。
- 新增 `/dev-workflow init --with-scripts`，仅在项目需要完全自包含时复制脚本。
- Git hooks 改为优先调用已安装 skill 目录中的 `check-dev-workflow.sh`，项目脚本只作为 fallback。
- 新增 `scripts/clean-project-scripts.sh`，用于预览并清理老项目中已复制的 dev-workflow 脚本副本。
- 脚本间调用改为优先使用 skill 内同目录脚本，支持从 skill 目录直接操作项目工作区。
- 更新 README、AGENTS 模板和 workflow 模板，默认指向 skill 脚本而不是项目 `scripts/`。

## 0.18.0 - 2026-06-11

- `scripts/search-dev-docs.sh` 现在会在本地索引缺失或真实文档比索引更新时自动运行 `scripts/reindex-dev-docs.sh`。
- `scripts/reindex-dev-docs.sh` 不再把生成文件 `docs/index.md` 写入机器索引，避免索引自我污染。
- 同步 harness 版本到 `0.18.0`，避免 doctor 在新版 skill 中误报项目 harness 过期。
- `/dev-workflow init` 会强制更新 `dev-workflow-harness.sh`、`search-dev-docs.sh`、`reindex-dev-docs.sh` 三个核心脚本，其它脚本和文档仍不覆盖。
- 更新 README 和模板说明：日常检索历史文档优先直接运行 `search-dev-docs.sh 关键词`。

## 0.17.0 - 2026-06-11

- 新增 `scripts/dev-workflow-harness.sh doctor`，检查项目初始化状态、项目 harness 版本、hooks、索引、`docs/index.md` 跟踪状态和下一步建议。
- harness 现在区分 `version`、`installed_skill_version`、`project_harness_version`，可发现老项目脚本是否过期。
- `run / report / verify` 新增 `flow_reason`，说明为何判定为 `quick / standard / strict`。
- `/dev-workflow init` 会强制更新项目内 `scripts/dev-workflow-harness.sh`，但继续不覆盖其它已有脚本和文档。
- 修正初始化脚本的 AGENTS 规则识别，避免新版 harness-first 规则被重复追加。

## 0.16.0 - 2026-06-11

- 将 dev-workflow 调整为 harness-first：自然语言开发任务默认先运行 `scripts/dev-workflow-harness.sh run "任务描述"`。
- 新增 harness `run` 和 `verify` 命令，输出下一步动作、需求验收完整性、验证证据状态、文档预算、人工审核和提交门禁状态。
- `verify` 明确输出 `requirement_match: pending-human-review`，只做机器完整性检查，不替代人工判断需求一致性。
- 大幅瘦身初始化写入的 `AGENTS.md` 规则，保留 harness 入口、硬门禁、上下文预算和需求一致性闭环。
- 更新 README、模板说明和 `workflow.md`，减少日常需要记忆的子命令。

## 0.15.0 - 2026-06-11

- 新增 `scripts/dev-workflow-harness.sh`，提供 `version / classify / check / report`。
- harness report 输出 `flow / docs_allowed / docs_changed / docs_index_tracked / human_review_required / commit_allowed`。
- harness check 会拦截仍被 Git 跟踪的 `docs/index.md`，提示执行 `git rm --cached docs/index.md`。
- 新增 `/dev-workflow version` 用法说明。
- 初始化会同步 harness 脚本到项目内。

## 0.14.0 - 2026-06-09

- 将 `docs/index.md` 从必需项目文件改为可选生成文件，避免多分支合并冲突。
- 初始化默认不再复制 `docs/index.md`。
- 文档检查不再要求 `docs/index.md` 存在。
- 初始化会把 `docs/index.md` 加入 `.gitignore`；旧项目可用 `git rm --cached docs/index.md` 停止跟踪。
- `reindex-dev-docs.sh --write-md` 仍可临时生成人类可读索引，但默认不提交。

## 0.13.0 - 2026-06-06

- 新增文档预算硬规则：quick 新增文档 0 个，standard 新增文档最多 1 个，strict 才允许完整链路。
- 明确普通任务禁止同时新建 `TASK + BUG + ACC`。
- 明确 standard 不创建 ACC，验收结论写进 BUG 或 TASK。
- 明确 `docs/index.md` 不作为任务产物，不因完成任务而手工更新。
- 当文档新增行数预计超过代码 / 测试改动行数时，优先降级文档写法。

## 0.12.0 - 2026-06-06

- 将默认流程从不确定时使用 `standard` 调整为默认从 `quick` 起步。
- 只有发现用户行为影响、需要追溯、跨少量文件或风险信号时，才升级到 `standard`。
- PRD、改版、多模块、接口、数据、核心链路、部署等明确风险仍自动升级到 `strict`。
- 同步更新 AGENTS 规则、项目 workflow 文档和 README 的默认分级说明。

## 0.11.0 - 2026-06-05

- 瘦身 `SKILL.md`，只保留最小硬规则、触发入口和 reference 指针。
- 将 4 个 reference 合并为 `references/flow.md` 和 `references/details.md`，消除重复规则。
- 将上下文预算、流程分级、本地索引和命名规则集中到 `references/flow.md`。
- 将 REQ、TDD、代码审查、人工审核、session、Superpowers / subagent 集中到 `references/details.md`。
- Final Response 改为按 `quick / standard / strict` 分级输出，减少 quick 任务 token 消耗。

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
