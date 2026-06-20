# 开发工作流

目标：让每次开发都能追踪“为什么做、改了什么、怎么验收、是否通过人工审核、提交在哪”，同时避免文档成为负担。

## 一、轻量原则

- 小任务只写必要信息，不补无关文档。
- 文档跟随代码一起改，完成时一次性补齐事实。
- 只有影响架构、接口、数据、部署、长期维护时，才写 ADR / design / ops。
- 已有项目不补全历史，只在当前改动需要时补 LEGACY 或补录 ADR。
- 没有文档同步和人工审核，不声明最终完成。

### Harness-first 执行入口

开发任务不要求用户记命令。收到自然语言任务后，先运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" run "用户任务描述"
```

如果项目脚本可能过期、hooks 不确定、或初始化状态不明，先运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" doctor
```

按输出的 `flow / docs_allowed / pre_code_gate / code_allowed / loop_phase / loop_next_decision / next_action` 执行。`code_allowed: false` 时，只能准备门禁文档，等待人工确认。

完成前运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" verify "用户任务描述"
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" check
```

`verify` 只检查完整性；需求是否一致必须由人工审核确认。

## 二、项目接入检查

使用本工作流前先检查：

- 是否存在 `AGENTS.md`。
- 是否存在 `docs/`。
- `docs/` 是否已有旧文档。
- 是否已有 `docs/workflow.md`、必要子目录和本地索引脚本；`docs/index.md` 不是必需文件。

处理规则：

- 没有 `AGENTS.md`：创建，并写入开发工作流强约束和文档查找优先级。
- 已有 `AGENTS.md`：保留原内容，只追加或更新工作流规则。
- 没有 `docs/`：创建标准目录骨架。
- 已有 `docs/` 但不是本工作流结构：把旧文档移动到 `docs/archive/legacy-docs-YYYYMMDD/`，再创建新结构。
- 已有本工作流结构：沿用，不覆盖已有文档。

旧文档归档后只作为历史参考，不作为当前实现依据。

初始化脚本：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/init-dev-workflow.sh"
```

默认初始化不会把 `TEMPLATE.md` 或通用脚本复制到项目目录，只创建文档目录和 Git hooks 入口。

如果项目需要自包含模板：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/init-dev-workflow.sh" --with-templates
```

Codex 快捷提示：

```text
/dev-workflow init
/dev-workflow 初始化项目
```

初始化并启用 Git hooks：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/init-dev-workflow.sh" --enable-hooks
```

Codex 快捷提示：

```text
/dev-workflow init --hooks
/dev-workflow 初始化项目并启用 hooks
```

## 三、文档查找优先级

处理需求、开发、修复、维护前，按以下顺序查找上下文：

1. `AGENTS.md`
2. `docs/workflow.md`
3. skill 脚本 `search-dev-docs.sh` 的候选结果，或 `.dev-workflow/index/docs.jsonl`
4. 当前任务关联的 `PRD / REQ / TASK / BUG / ADR / ACC`
5. `docs/design/` 和 `docs/ops/`
6. `docs/legacy/`
7. `docs/archive/`
8. 代码和测试

如果当前代码与 `docs/archive/` 中的旧文档冲突，以当前代码和当前链路文档为准。

## 四、文档读取预算

默认只读：

- `AGENTS.md`
- `docs/workflow.md`
- skill 脚本 `search-dev-docs.sh` 的候选结果，或 `.dev-workflow/index/docs.jsonl` 中的少量匹配行
- 用户当前提供的 PRD / 需求 / Bug 描述
- 与当前任务直接相关的文档

默认禁止全量读取：

- `docs/archive/**`
- 全部 PRD
- 全部 REQ
- 全部 TASK
- 全部 BUG
- 全部 ACC
- 全部 ADR

先用 skill 脚本 `search-dev-docs.sh` 根据当前任务关键词、模块名、功能名、编号筛选候选文档。候选过多时，先列候选和选择依据。

## 五、本地索引

`.dev-workflow/index/docs.jsonl` 是可重建机器索引，默认不提交。

日常检索：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/search-dev-docs.sh" login
```

索引缺失或真实文档更新时，`search-dev-docs.sh` 会自动重建。需要手动重建时执行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/reindex-dev-docs.sh"
```

`docs/index.md` 只是可选的人类可读生成文件，不再作为每次任务必须手工更新的共享索引。如果需要临时生成可读索引，可执行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/reindex-dev-docs.sh" --write-md
```

`docs/index.md` 默认加入 `.gitignore`，不要提交，避免多分支合并冲突。

## 六、自动流程分级

默认自动选择流程强度，不要求用户手动指定。先用 skill 脚本 `dev-workflow-harness.sh run "任务描述"` 获取初始护栏和 `flow_reason`。默认从 `quick` 起步，只有发现明确风险信号才升级：

- `quick`：文案、样式、小配置、小功能、小 Bug、单文件或低风险改动。少读历史，默认只写摘要。
- `standard`：普通 Bug、普通功能调整、单模块功能。编码前先确认一个 `TASK` 或 `BUG` 主记录，验证、审查、验收结论写在同一文档。
- `strict`：PRD、产品文档、现有功能改版、多模块、高风险、接口/数据/权限/支付/订单/登录/部署变化。必须 `PRD + REQ + TASK + ACC`。

优先级：硬门禁 > 风险自动升级 > 文档预算 > 用户指定 > 默认 quick。

如果用户指定 `quick` 但出现 PRD、改版、接口、数据、核心链路等风险，必须自动升级并说明原因。任务类型不确定但未发现明确风险时，默认 `quick`；发现用户行为影响、需要追溯或跨少量文件时，升级为 `standard`。

文档预算：

- quick：新增文档 0 个；最终回复摘要即留痕。
- quick 且用户要求留痕：最多 1 个 TASK。
- standard：新增文档最多 1 个，Bug 用 BUG，功能 / 维护用 TASK；这个主记录必须编码前确认。
- standard 不创建 ACC；验收结论写进 BUG 或 TASK。
- strict 才允许完整链路；普通任务不得同时创建 `TASK + BUG + ACC`。
- `docs/index.md` 不作为任务产物，不因完成任务而手工更新；默认加入 `.gitignore`，不要提交。

## 七、命名规则

统一使用时间戳编号，避免多电脑、多分支并行时产生序号冲突：

```text
TYPE-YYYYMMDD-HHMMSS-XXXX-short-title.md
```

- `TYPE`：`PRD / REQ / TASK / BUG / ADR / ACC / OPS / LEGACY`。
- `YYYYMMDD-HHMMSS`：创建文档时的本地时间。
- `XXXX`：4 位小写随机码。
- `short-title`：英文短标题，使用小写和连字符。

示例：

```text
tasks/TASK-20260528-153500-b2c3-login-api.md
requirements/REQ-20260529-101500-a1b2-member-revamp.md
bugs/BUG-20260528-154000-c3d4-token-expired.md
acceptance/ACC-20260528-155000-e5f6-user-login.md
```

旧项目中的 `TASK-0001` 这类编号继续有效，但新文档一律使用时间戳编号。

## 八、模板保护

`docs/**/TEMPLATE.md` 是母版，只能复制，不能作为任务文档直接填写。

默认模板保存在已安装的 dev-workflow Skill 中，不放进项目目录。

新建文档时优先使用：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/new-doc.sh" TASK login-api
```

如果没有脚本，先复制对应 `TEMPLATE.md` 到带编号的新文件，再填写新文件。

如果项目需要自包含模板，使用 skill 脚本 `init-dev-workflow.sh --with-templates`。

已经初始化过的旧项目如需清理模板：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/clean-templates.sh"
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/clean-templates.sh" --apply
```

日常开发、Bug 修复、验收、改版时，禁止直接修改任何 `TEMPLATE.md`。只有明确提出“修改模板”或“升级 dev-workflow 模板”时，才允许改模板。

## 九、最小闭环

### 编码前门禁

- quick：`pre_code_gate: not_required`，低风险小改可直接实现。
- standard：`pre_code_gate: confirm_TASK_or_BUG_before_code`，先写并确认一个 TASK 或 BUG。
- strict：`pre_code_gate: confirm_REQ_before_code`，先写并确认 REQ。

确认标记统一为：

```text
编码前确认：已确认
```

用户在对话中明确确认门禁文档后，才允许把标记改为 `已确认` 并开始编码。

### Adaptive Loop

Loop 是执行节奏控制，不是新的重文档模板。每轮只做一个可验证动作：

```text
理解当前状态 -> 选择一个小动作 -> 执行 -> 验证证据 -> 决定继续 / 修正 / 停止 / 等人确认
```

harness 字段：

- `loop_phase`：当前阶段。
- `loop_next_decision`：继续、重试、等待人工或停止。
- `max_iterations`：quick 1，standard 3，strict 5。
- `stop_condition`：本轮停止条件。
- `slice_strategy`：是否需要自适应切片。

自适应切片：

1. 优先按需求文档自身结构切片。
2. 再按项目代码边界切片。
3. 再按风险点切片。
4. 最后按可独立验证的粒度切片。

每个 slice 必须写清：目标、不做什么、改动范围、验收方式、验证证据、停止条件。不套固定业务分类。

### 真实验证门禁

最终验收必须来自真实后端、真实接口、真实运行环境、本地前后端联调、测试环境、真实数据链路或人工实测记录。

mock 数据、fixture、stub、MSW、Playwright route mock、接口拦截和模拟接口只能做开发辅助或补充测试，不能作为最终验收，也不能作为真实环境不可用时的降级验收。

如果真实环境不可用，结论只能是 `blocked` 或 `pending-real-verification`。TASK / BUG / ACC 和最终回复必须写清最终验收来源、最终验收证据、是否存在辅助模拟测试。

### quick 小改

必需：最终回复摘要

按需：一个 `TASK`

流程：

1. 少读历史，只看当前任务和必要代码。
2. 修改并做最小验证。
3. 自查需求是否偏离、是否有无关改动。
4. 最终回复列出改动、验证、待审核文件。
5. 不默认创建 TASK / BUG / ACC。

### standard Bug

必需：一个 `BUG` 主记录

按需：`TASK / ACC / ADR / design / ops`

流程：

1. BUG 写清现象、复现、根因、修复方案。
2. 写清验收项和测试方式。
3. 等待人工确认，并把 `编码前确认` 改为 `已确认`。
4. 先写复现测试，或记录无法自动化原因。
5. 修复并验证。
6. 在 BUG 中记录验证结果、代码审查和验收结论。
7. 需要复杂验收或高风险时，再创建 ACC。
8. 索引由 `search-dev-docs.sh` 或 `check` 按需重建。
9. 进入提交前人工审核。

### standard 功能 / 维护 / 重构

必需：一个 `TASK` 主记录

按需：`BUG / ACC / ADR / design / ops`

流程：

1. TASK 写清目标、非目标、改动范围。
2. 写清验收项和测试方式。
3. 等待人工确认，并把 `编码前确认` 改为 `已确认`。
4. 修改并验证。
5. 在 TASK 中记录实际改动、验证结果、代码审查和验收结论。
6. 需要复杂验收或高风险时，再创建 ACC。
7. 索引由 `search-dev-docs.sh` 或 `check` 按需重建。
8. 进入提交前人工审核。

### strict 新功能 / PRD 改版 / 已有功能改版

必需：`PRD + REQ + TASK + ACC`

按需：`ADR / design / ops / LEGACY`

门禁：

- 没有 REQ 需求追踪矩阵，不编码。
- REQ 未经人工确认，不编码。
- REQ 的 `编码前确认` 未标记为 `已确认`，不编码。
- 每个 TASK 必须关联一个或多个 REQ。
- 每个 ACC 必须验收对应 REQ。
- 有测试框架时优先 TDD；没有测试框架时必须写手工验收项和无法自动化原因。

流程：

1. 阅读 PRD 原文，保留原文依据。
2. 查找历史 PRD / REQ / TASK / BUG / ADR / ACC。
3. 阅读现有代码，定位当前实现路径。
4. 输出当前实现与 PRD 目标行为差异。
5. 创建 REQ 需求追踪矩阵。
6. 为每个 REQ 写验收方式和测试计划。
7. 列出待确认问题。
8. 等待人工确认。
9. 把 REQ 的 `编码前确认` 改为 `已确认`。
10. 确认后再创建 TASK 并进入 TDD 实现。

## 十、什么时候写 ADR

满足任一条件才写：

- 改变架构或模块边界。
- 改变接口契约或数据模型。
- 做技术选型。
- 放弃过一个看似合理的方案，未来可能再次被提出。
- Bug 根因来自历史设计问题。

## 十一、什么时候更新 ops

满足任一条件才更新：

- 部署方式变化。
- 配置项变化。
- 监控、告警、日志定位方式变化。
- 回滚方式变化。
- 应急处理步骤变化。

## 十二、已有项目接入

首次接入只需要一份现状快照：

```text
legacy/LEGACY-20260528-160000-a7b8-current-system-summary.md
```

之后从当前任务开始追踪。当前改到哪个模块，就补哪个模块需要的历史，不做全量补档。

## 十三、完成前检查

最终回复前必须确认：

- 如环境不确定，已运行 skill 脚本 `dev-workflow-harness.sh doctor`。
- 已运行 skill 脚本 `dev-workflow-harness.sh verify "任务描述"`。
- 已运行 skill 脚本 `dev-workflow-harness.sh check`。
- 已按流程级别创建或更新文档；quick 可无正式文档。
- PRD / 改版任务已建立并确认 REQ 需求追踪矩阵。
- standard 的 TASK 或 BUG 写明编码前确认、实际改动、验证结果、代码审查和验收结论。
- strict 的 ACC 写明验收结论，并覆盖对应 REQ / BUG。
- 有测试框架时已优先使用 TDD；无法自动化时已记录原因和手工验收项。
- 必要的 ADR / design / ops 已处理，或明确“不需要”。
- 本地索引已重建或可重建。
- 已列出待人工审核内容和待提交文件。

可执行脚本检查：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/check-dev-docs.sh"
```

Codex 快捷提示：

```text
/dev-workflow check
/dev-workflow 检查文档
```

## 十四、代码审查规则

代码审查是完成前门禁，但保持轻量：

- 小任务：执行自查，重点看需求偏离、无关改动、错误处理、测试缺口、文档同步。
- 复杂 / 高风险任务：使用 subagent 或人工做独立 review。
- 审查发现的问题必须先修复，或记录为遗留问题并关联后续 TASK。
- 审查结论回填到主记录；quick 可只在最终回复列出。

## 十四、TDD 规则

新功能、PRD 改版、Bug 修复默认优先使用 TDD：

- 编码前先写测试或手工验收项。
- 每个测试或验收项必须关联 REQ / BUG。
- 有测试框架时，先确认目标测试失败，再编码让测试通过。
- 已有功能改版时，先记录当前行为，再写 PRD 目标行为测试。
- 没有测试框架或不适合自动化时，在最终摘要、主记录或 strict 的 ACC 里记录原因，并写手工验收项。

PRD 改版时，TDD 的输入必须来自 REQ 需求追踪矩阵，而不是模糊摘要。

## 十五、提交前人工审核

默认不自动提交代码。

完成开发、验证、必要自查和文档同步后，必须先进入人工审核：

- 列出代码变更摘要。
- 列出验证结果。
- 列出代码审查结论。
- 列出文档同步清单。
- 列出待提交文件。
- 等待用户明确回复“批准提交”或“确认提交”。

只有收到明确批准后，才提交代码和文档。

## 十六、提交规则

提交必须聚焦，只包含本次任务相关文件。

commit message 引用主编号：

```text
TASK-20260528-153500-b2c3 implement login api
BUG-20260528-154000-c3d4 fix token refresh failure
PRD-20260528-153000-a1b2 add user login workflow
```

## 十七、Subagent 使用规则

默认不使用 subagent。满足以下任一条件时才使用：

- 任务涉及多个独立模块。
- Bug 根因不明确。
- 需要并行调查代码路径、测试、文档或影响范围。
- 改动影响范围较大。
- 完成前需要独立 review 或 QA 检查。

subagent 的结论必须回填到对应文档：

- quick：最终回复列出关键结论。
- standard：结论写入 TASK 或 BUG 主记录。
- strict：结论写入 PRD / REQ / TASK / BUG / ACC / ADR 中的对应位置。

## 十八、Git hooks 门禁

`.githooks/` 是可选门禁模板，默认不自动启用。正式项目建议启用，临时项目可以不启用。

启用后，每次 `git commit` 都会执行轻量检查：

- `pre-commit`：默认检查文档结构并重建索引。
- `commit-msg`：提交信息建议包含追踪编号；quick 可使用 `[quick]`。
- 需要强制代码变更伴随文档时，设置 `DEV_WORKFLOW_REQUIRE_DOCS=1`。

启用方式：

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit .githooks/commit-msg
```

确认是否启用：

```bash
git config core.hooksPath
```

输出 `.githooks` 表示已启用。

关闭方式：

```bash
git config --unset core.hooksPath
```

跳过规则仅用于纯文档、临时实验或紧急情况。跳过后必须补一条 TASK 或 BUG 记录说明原因。
