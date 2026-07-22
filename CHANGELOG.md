# Changelog

## 1.0.0 - 2026-07-22

- 重构为 Native Agent 工作流：普通任务直接调查、实现、验证和审查，复杂任务使用宿主原生 Plan mode，不再自建规划器或 Loop。
- 删除默认 TASK_KEY、文件 track、manifest 和开发前同文件阻断；`commit-scope.sh`仅保留为显式特殊工具。
- subagent 默认用于检索、日志、测试和审查，主 Agent 负责共享工作区的最终写入与完成声明。
- 普通任务只使用结构化 Git commit 留痕；跨会话、高风险或长期追溯任务只维护一个 DEV。
- Git hooks 不再读取 manifest 或阻断多个线程，只校验实际修改的 DEV，并提示提交信息格式。
- `init`会迁移旧版 AGENTS 规则，不移动已有 docs，不默认创建目录、复制模板、安装脚本或启用 hooks。
- 删除 harness、Loop、ACTIVE 会话状态、本地索引及旧 REQ/TASK/BUG/CHG/ACC 模板和脚本镜像，Skill 文件总量显著下降。
- Skill 不固定模型或推理级别，可由 Codex、Claude 或其他宿主按任务选择当前能力。

## 0.37.0 - 2026-07-15

- 恢复“本线程提交本线程文件”的默认体验：新增 `commit-scope.sh track TASK_KEY -- FILE...`，由 Agent 在修改前后台增量记录，用户无须管理清单。
- track 只记录本线程触碰的文件，不要求分类整个工作区；同一文件已被其他线程记录时提前阻断，避免提交阶段才发现重叠。
- 已有 track 记录与后续 prepare 自动取并集，防止提交前重建清单时遗漏早先修改的文件。
- 正常情况仍由原线程直接提交，不引入统一收口或全局任务队列。
- 只有 commit 成功、HEAD 实际变化、HEAD 文件与本线程记录一致且当前线程文件无残留时，才能声称提交成功。

## 0.36.0 - 2026-07-15

- 取消每次正式代码提交必须新增 CHG 的门禁；普通 Bug、功能、重构和维护只使用结构化 Git commit 留痕。
- 新增统一 `DEV` 生命周期文档，复杂或高风险任务在一个文件中维护需求基线、实现计划、问题决策、验收矩阵、进度和关联 commits。
- REQ、TASK、BUG、CHG、ACC 保留旧历史兼容和检索能力，但新任务不再默认创建，也不组成配套文档链。
- 新项目不再创建对应的五个空目录；旧项目已有目录和文档保持原样，不删除、不迁移。
- `new-doc.sh`、命名、初始化、索引和 harness 支持 `DEV`；旧项目重新 init 会追加 Git/DEV 覆盖规则，不删除或迁移旧文档。
- 提交审核包不再包含强制 CHG，只展示文件范围、完整 commit message、验证结果和可选 DEV 变化。

## 0.35.1 - 2026-07-15

- 提交审核改为单次授权：首次询问前一次性展示文件范围、CHG、完整 commit message 和验证结果。
- 用户确认后必须立即精确暂存并提交，不得为暂存、hooks 或真正 commit 重复询问。
- 仅当确认后的审核包内容实际变化时，授权失效并重新确认一次；旧项目重新 init 会追加该规则。

## 0.35.0 - 2026-07-15

- 精确提交从单一 `.dev-workflow/commit-manifest.txt` 改为任务独立 `.dev-workflow/commits/TASK_KEY.txt`，多个任务不再互相占用提交事务。
- 新增 `commit-scope.sh commit TASK_KEY ...`，通过 `git commit --only`只提交当前任务文件，保留其他任务已经暂存的文件。
- 共享工作区不再要求使用 `--other`完整分类其他任务；只有不同任务清单包含同一文件时才阻断并要求人工确认。
- hooks 通过当前任务 manifest 校验 CHG、结构化提交信息和 HEAD 文件范围；存在多个清单时，直接 `git commit` 会提示改用任务级精确提交。
- 保留旧单 manifest 的读取兼容；旧项目重新运行 `/dev-workflow init`即可追加新规则和本地 commits 目录。

## 0.34.0 - 2026-07-15

- 新增精简 `CHG` 记录：正式代码提交默认恰好新增一个 `docs/changes/YYYY/MM/CHG-*.md`，不配套创建 REQ、TASK、BUG 或 ACC。
- CHG 仅包含 `id / type / module / created_at / files / related` 元数据和“原因/变更/验证/影响”四项正文，与代码和结构化 commit message 同一提交。
- `new-doc.sh` / `new-doc-id.sh` 支持 CHG 和按年月存放；命名使用时间戳加随机 ID，避免多电脑、多分支冲突。
- 精确提交门禁对代码提交校验一个新 CHG 及其完整字段；临时提交或用户明确不留文档时可用 `DEV_WORKFLOW_SKIP_CHG=1` 跳过。
- hooks 只检查本次 staged CHG，不扫描全部历史，也不在提交时重建索引；知识图谱仅预留字段，暂不生成数据库。

## 0.33.0 - 2026-07-15

- 增加“提交即留痕”：普通 Bug、功能完善和维护不新建 REQ、TASK、BUG 或 ACC，在提交审核时根据实际 diff 生成结构化 Git commit message。
- 提交记录固定包含类型/模块摘要、原因、变更、验证和影响；人工审核同时确认文件范围和记录内容。
- 新增 `/dev-workflow history <关键词|文件>` 语义，使用 `git log / blame / show` 追查历史，不维护额外的普通变更文档索引。

## 0.32.0 - 2026-07-14

- 改为 Dev Workflow Lite：普通 Bug、功能、重构和维护默认直接调查、实现、测试和审查，不再自动运行 harness、Loop、索引或创建任务文档。
- ACTIVE 只用于跨会话、换 agent、多人并行或明确交接；REQ 只用于 PRD 改版和高风险变更。
- harness 分类不再把“Bug / 修复 / 功能”自动升级 standard，输出精简为可直接决策的状态；索引缺失不再导致 doctor 建议每次 check。
- Git hooks 改为可选审计：只在存在 commit manifest 时强制精确范围，只在暂存 docs / AGENTS.md 时检查文档，commit message 缺少追踪编号只警告。
- 大幅精简 `SKILL.md`、references、README 和项目文档模板；旧项目重新 init 时追加 Lite 覆盖规则，不需要删除原有文档。

## 0.31.0 - 2026-07-14

- 新增对话级 ACTIVE 本地绑定：选择顺序固定为 exact 路径、当前对话绑定、唯一关键词匹配，长对话和并行任务不再反复猜测自己的文档。
- `active-work.sh` 新增 `current / bind / unbind / resolve`，`start` 自动绑定，`finish` 自动清理失效绑定；Codex 使用 `CODEX_THREAD_ID`，其他 agent 可传 `DEV_WORKFLOW_CONTEXT_ID`。
- 新增 `commit-scope.sh` 精确提交清单，支持 `prepare / show / stage / check / verify-head / clear`；完整覆盖 staged、unstaged、untracked 文件，拦截未分类文件、其他任务暂存、漏文件、额外暂存、暂存后再修改，并核对提交前后 HEAD。
- 明确禁止用 `git add .`、`git add -u`、`git commit -am` 代替任务清单；并行任务优先独立 Git worktree，共享工作区的其他文件必须逐项确认归属。
- 启用 hooks 后，pre-commit 强制要求任务清单并核对暂存范围；同时支持已暂存重命名和 `#` 开头文件名，提交后通过 `verify-head` 核对 HEAD 文件集合并清理清单。
- 新增 `post-commit` hook，commit 成功后自动执行 `verify-head` 并清理已完成任务的提交清单，避免阻塞下一个并行任务。
- `/dev-workflow init` 现在整体忽略 `.dev-workflow/`，并给老项目补充任务绑定与提交范围规则；harness doctor/check 会提示重新初始化或移除旧的 Git 跟踪状态。
- 更新 Codex `agents/openai.yaml` 为 `interface` 元数据格式，并同步 README、workflow、references 和自包含脚本模板。

## 0.30.0 - 2026-07-12

- 新增编码前实现地图：standard / strict 必须列出真实调用链、计划修改、受影响不改和测试/回归文件，范围扩大时暂停并重新确认。
- 新增复用决策：先搜索并复用或扩展已有能力，只有真实调用方、业务语义和稳定契约满足条件时才抽公共函数、类或组件。
- 新增前端大文件治理：500 行触发职责评估，800 行或新增独立职责时必须写拆分决策；组件、hook/composable、service/api、模块 utils 和 CSS 按职责拆分。
- ACTIVE、TASK、BUG、REQ 模板新增实现地图、复用评估、文件健康和计划偏差字段，不增加新的文档类型。
- 修正 ACTIVE 测试表头与 harness 质量检查不一致的问题，避免已确认测试用例被误判为缺少关联字段。
- harness 新增 `implementation_map_policy / reuse_policy / file_health_policy / scope_expansion_policy`，`verify` 会阻断缺少实现地图关键字段的 standard / strict 代码变更。
- `/dev-workflow init` 会给旧项目 AGENTS.md 补充 Implementation Map Guard；默认仍不自动提交代码。

## 0.29.0 - 2026-06-25

- 新增轻量注释策略：新增或修改关键业务代码时默认补简短中文注释，说明职责、业务原因、边界或需求关联。
- 明确注释预算：quick 只在不注释会看不懂时补；standard 关键业务逻辑必须补；strict 关键规则注释关联 REQ / 验收项。
- harness 新增 `comment_policy / comment_budget` 输出，完成前自查关键逻辑是否缺注释、注释是否过时或空泛。
- `/dev-workflow init` 会给老项目 `AGENTS.md` 补充 Comment Guard，不覆盖原有内容。

## 0.28.0 - 2026-06-24

- 新增 `scripts/loop-work.sh` 试验版：在 ACTIVE 内记录 `step / verify / decide / status`，让 loop 从提示变成可检查的短闭环。
- 每轮 `step` 必须绑定关联验收项；`continue / retry / rescope` 前必须已有本轮真实验证证据。
- `wait_human / stop` 可直接决策，且决策后禁止继续开新轮；达到最大轮次后停止并汇报。
- doctor / clean-scripts 识别 `loop-work.sh`，项目自包含脚本模式会同步该脚本。

## 0.27.0 - 2026-06-22

- `/dev-workflow init` 现在会为已存在旧 dev-workflow 规则的项目补充 `Dev Workflow Active Isolation` 段落。
- 老项目运行 init 后也能获得 `active-work.sh match` / `ambiguous_active` 防串台规则，不需要重建 docs 或覆盖原 AGENTS 内容。

## 0.26.0 - 2026-06-22

- 新增 ACTIVE 隔离门禁：多个 ACTIVE 同时存在时，必须先锁定唯一文件，禁止按模块名、最近时间或猜测选择，降低多线程任务串台风险。
- `active-work.sh match keyword...` 支持按关键词匹配 ACTIVE；无命中退出 1，多命中输出 `ambiguous_active` 并退出 2，只命中 1 个时输出 exact 文件路径。
- `active-work.sh start` 自动写入标题、ACTIVE 文件、任务指纹、分支、创建时间和最后更新时间，减少占位符和误判。
- harness 新增 `active_isolation_policy: exact_ACTIVE_required_ambiguous_match_stops` 输出。
- 更新 SKILL、references、AGENTS 模板、workflow 和 README，明确未锁定 ACTIVE 前不得读取或回填候选内容。

## 0.25.0 - 2026-06-22

- 新增 `scripts/active-work.sh`，支持 `start / list / template / finish`，减少 ACTIVE 创建、查看、折叠到 history 和清理时的手工操作。
- `finish` 要求人工审核后执行，且 history 摘要最多 8 个非空行，避免 history 重新膨胀。
- doctor 和 clean-scripts 识别 `active-work.sh`，项目自包含脚本模式也会同步该脚本。
- 更新 SKILL、README、workflow、ACTIVE 模板和 references，补充 ACTIVE 生命周期脚本用法。

## 0.24.0 - 2026-06-22

- 新增 `docs/active/ACTIVE-*.md` 进行中交接模式：普通 standard 任务默认先确认 ACTIVE 和测试用例清单，复杂或高风险才升级为 TASK / BUG。
- 新增 `docs/history/<module>.md` 模块级短历史：任务完成并通过人工审核后，把 8 行以内摘要折叠到 history，再清理 ACTIVE，减少永久文档膨胀。
- harness 升级到 `0.24.0`，`standard` 前置门禁改为 `ACTIVE_or_TASK_or_BUG`，并输出 `active_policy / history_policy / formal_doc_policy`。
- 初始化、检查、索引、新建文档脚本支持 `active/` 和 `history/`；本地索引可识别 `ACTIVE` 和 `HISTORY`。
- 更新 SKILL、references、AGENTS 模板、workflow、README 和模板，明确多线程、多分支、多电脑并行时用独立 ACTIVE 接力，不使用全局 `current-work.md`。

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
