# Flow

## 自动分级

默认自动分级，不要求用户手动选择。自然语言开发任务先运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" run "任务描述"
```

默认从 `quick` 起步；只有发现明确风险信号，才升级到 `standard` 或 `strict`。用户可以显式覆盖：`quick / standard / strict`。

`run` 输出初始护栏、`flow_reason`、`pre_code_gate`、`code_allowed`、`loop_phase`、`loop_next_decision` 和下一步动作；完成前运行 `verify` 和 `check`。这些输出不替代硬门禁和人工审核。

优先级：

```text
硬门禁 > 风险自动升级 > 文档预算 > 用户指定 > 默认 quick
```

用户指定不是绝对命令。如果用户指定 `quick`，但任务包含 PRD、产品文档、改版、多模块、接口、数据、核心链路、部署等风险，必须自动升级并说明原因。

### quick

适用：

- 文案修改。
- 样式微调。
- 小范围配置。
- 单文件无业务逻辑改动。
- 小功能、小 Bug，且未发现接口、数据、核心链路、部署等风险。
- 开发辅助脚本。
- 不影响用户行为的轻维护。

流程：

- 不创建 PRD / REQ。
- 默认不创建 TASK / BUG / ACC。
- 文档新增数量为 0；如果用户明确要求留痕，最多创建或更新 1 个 ACTIVE 或 TASK。
- 不读完整历史文档。
- 简单验证和自查。
- 只在用户要求、变更需要长期追溯、或已有对应正式记录时，创建或更新一个 ACTIVE 或 TASK。
- 不单独创建 ACC；验收结论写在最终回复或 TASK 的验证段。
- 不自动 commit，进入人工审核。

quick 禁用场景：

- PRD / 产品文档。
- 现有功能改版。
- 多模块改动。
- 接口变化。
- 数据结构变化。
- 权限 / 支付 / 订单 / 登录等核心链路。
- 部署 / 配置 / 监控变化。
- 用户要求完整流程。

### standard

适用：

- 普通 Bug。
- 普通功能调整。
- 单模块功能。
- 有明确验收标准。
- 影响用户行为但风险可控。
- 跨少量文件，或需要留下一个主记录方便追溯。

流程：

- 默认只建一个 `ACTIVE` 进行中交接文件。
- Bug 或功能复杂、需要长期追溯、影响面扩大、用户要求正式记录时，才升级为 `BUG` 或 `TASK` 主记录。
- 编码前必须写清目标、范围、不做什么、验收项、测试方式和测试用例清单，并等待人工确认。
- 人工确认后把 ACTIVE / TASK / BUG 中的 `编码前确认` 和 `测试用例确认` 改为 `已确认`，再开始编码。
- 文档新增数量优先为 1 个 ACTIVE；完成时折叠到 1 个模块 history。禁止为同一个普通任务同时新建 `TASK + BUG + ACC`。
- 验证、代码审查、验收结论先写入 ACTIVE / 主记录，不单独创建 ACC。
- 只有用户要求、发布验收复杂、或 strict 升级时，才创建 ACC。
- 优先 TDD；无法自动化则写手工验收。
- 人工审核通过后，把 ACTIVE 摘要折叠到 `docs/history/<module>.md`，再删除 ACTIVE。
- 验证、代码审查、文档同步、人工审核。

### strict

适用：

- PRD / 产品文档。
- 现有功能改版。
- 多模块或高风险改动。
- 架构、接口、数据模型、权限、支付、订单、登录。
- 部署、配置、监控、回滚变化。

流程：

- 新功能 / 改版：`PRD + REQ + TASK + ACC`。
- 高风险 Bug 可使用 `BUG + TASK + ACC`。
- 必要时 `ADR / design / ops / legacy`。
- REQ 和测试用例矩阵未经人工确认前不编码；确认后把 `编码前确认` 和 `测试用例确认` 改为 `已确认`。
- TDD 或明确手工验收项，测试用例必须从 REQ 行为倒推。
- 必要时 subagent 或人工独立 review。

## 自动升级

从 `quick` 开始。一旦发现风险条件，自动升级并说明原因：

```text
本次从 standard 升级为 strict，原因：发现接口契约变化。
```

如果任务类型不确定，但未发现明确风险，默认 `quick`。发现影响用户行为、需要根因记录、跨少量文件或需要追溯时，升级为 `standard`。

只在以下情况询问用户：

- 任务描述太短，无法判断是否影响业务。
- 疑似涉及核心链路但证据不足。
- 用户强行要求 quick，但检测到疑似高风险且证据不足。

其他情况直接自动判断，不增加用户操作负担。

## 文档预算

文档预算优先于“补完整链路”的冲动：

- quick：新增文档 0 个；最终回复摘要即留痕。
- quick 且用户要求留痕：最多 1 个 ACTIVE 或 TASK。
- standard：默认新增 1 个 ACTIVE；复杂或高风险才使用 BUG / TASK；完成时追加 1 条模块 history。
- standard 不创建 ACC；验收结论写进 ACTIVE / BUG / TASK，完成摘要写进 history。
- strict 才允许完整链路；普通任务不得同时创建 `TASK + BUG + ACC`。
- `docs/index.md` 不作为任务产物，不因完成任务而手工更新；默认加入 `.gitignore`，不要提交。

如果文档新增行数预计超过代码 / 测试改动行数，先降级文档写法：摘要 > ACTIVE > 正式记录 > 完整链路。

## 命名规则

新文档统一使用：

```text
TYPE-YYYYMMDD-HHMMSS-XXXX-short-title.md
```

- `TYPE`：`PRD / REQ / TASK / BUG / ACTIVE / ADR / ACC / OPS / LEGACY`。
- `YYYYMMDD-HHMMSS`：创建文档时的本地时间。
- `XXXX`：4 位小写随机码。
- `short-title`：英文短标题，使用小写和连字符。

使用 skill 脚本 `new-doc-id.sh` 生成编号；项目自包含模式下也可使用项目内副本。

## 上下文预算

目标：避免每次任务全量读取历史文档，减少 token 和旧文档干扰。

默认只读取：

- `AGENTS.md`
- `docs/workflow.md`
- skill 脚本 `search-dev-docs.sh` 的候选结果，或 `.dev-workflow/index/docs.jsonl` 中的少量匹配行
- 用户当前提供的 PRD / 需求 / Bug 描述
- 与当前任务直接相关的文档

不要默认读取：

- `docs/archive/**`
- 全部 PRD
- 全部 REQ
- 全部 TASK
- 全部 BUG
- 全部 ACC
- 全部 ADR

查找顺序：

1. 先读 `AGENTS.md` 和 `docs/workflow.md`。
2. 用 `active-work.sh match 关键词` 锁定当前任务唯一 ACTIVE；多个命中时先让用户确认，不读任何候选内容。
3. 读当前模块的 `docs/history/<module>.md`；只看最近相关条目。
4. 用 skill 脚本 `search-dev-docs.sh 关键词` 按任务关键词、模块名、功能名、编号筛选候选文档；索引缺失或真实文档更新时，search 会自动重建。
5. 只打开候选文档中最相关的 1-5 个；候选过多时，先列出候选和选择依据。
6. 只有搜索结果不足、任务涉及历史行为、或当前代码与文档冲突时，才搜索更多 docs 或 archive。

## 本地索引

`.dev-workflow/index/docs.jsonl` 是可重建的机器索引，默认不提交。它用于快速定位文档，避免读取全部历史文档。

`docs/index.md` 只是可选的人类可读生成文件，默认加入 `.gitignore`，不作为必需项目文件，也不提交。

## ACTIVE / history 规则

- 不使用全局 `docs/active/current-work.md`；多个线程、分支、电脑并行时，每个任务一个 `ACTIVE-YYYYMMDD-HHMMSS-XXXX-short-title.md`。
- ACTIVE 是进行中状态和交接文件，记录目标、范围、下一步、测试用例、真实验证证据和代码审查。
- 完成前先用 ACTIVE 通过 `verify` 和人工审核；审核通过后把 8 行以内摘要折叠到 `docs/history/<module>.md`，再删除 ACTIVE。
- history 是模块级短历史，只保留结论、验证、提交和关联编号；需要细节时通过提交号、PR、REQ/TASK/BUG 或 archive 追溯。
- 如果任务中途暂停、换 agent、换电脑，不删除 ACTIVE；新 agent 先读相关 ACTIVE 再继续。
- 后续再次修改同一功能：如果上次 ACTIVE 仍未完成，继续更新它；如果已经完成，读 history 后创建新的 ACTIVE 或正式文档。

## archive 规则

`docs/archive/` 默认不读。只有满足以下条件才读：

- 当前任务明确依赖归档历史。
- `legacy` 或当前文档引用了 archive。
- 用户要求追溯旧历史。

如果当前代码与 archive 冲突，以当前代码和当前链路文档为准。

## 编码前门禁

- quick：`pre_code_gate: not_required`，低风险小改可直接实现。
- standard：`pre_code_gate: confirm_ACTIVE_or_TASK_or_BUG_and_test_cases_before_code`，默认先确认 `ACTIVE` 及测试用例清单；复杂或高风险才确认 `TASK` / `BUG`。
- strict：`pre_code_gate: confirm_REQ_and_test_cases_before_code`，先确认 `REQ` 及测试用例矩阵。

确认标记统一写为：

```text
编码前确认：已确认
测试用例确认：已确认
```

用户在对话中明确确认门禁文档和测试用例清单后，才允许把两个标记改为 `已确认` 并开始编码。

## 文档写入策略

小任务不要一开始就写很多文档：

- quick：默认不写正式文档，只在最终回复摘要；必要时一个 TASK。
- standard：编码前先确认一个 ACTIVE；复杂或高风险才用 TASK / BUG。完成前回填实际改动、验证、审查和验收结论；审核后折叠到 history，不额外创建 ACC。
- strict：PRD / 改版必须先写 REQ 和测试用例矩阵，确认后再编码。
