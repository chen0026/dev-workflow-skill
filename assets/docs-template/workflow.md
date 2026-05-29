# 开发工作流

目标：让每次开发都能追踪“为什么做、改了什么、怎么验收、是否通过人工审核、提交在哪”，同时避免文档成为负担。

## 一、轻量原则

- 小任务只写必要信息，不补无关文档。
- 文档跟随代码一起改，完成时一次性补齐事实。
- 只有影响架构、接口、数据、部署、长期维护时，才写 ADR / design / ops。
- 已有项目不补全历史，只在当前改动需要时补 LEGACY 或补录 ADR。
- 没有文档同步和人工审核，不声明最终完成。

## 二、项目接入检查

使用本工作流前先检查：

- 是否存在 `AGENTS.md`。
- 是否存在 `docs/`。
- `docs/` 是否已有旧文档。
- 是否已有 `docs/workflow.md`、`docs/index.md` 和必要子目录。

处理规则：

- 没有 `AGENTS.md`：创建，并写入开发工作流强约束和文档查找优先级。
- 已有 `AGENTS.md`：保留原内容，只追加或更新工作流规则。
- 没有 `docs/`：创建标准目录骨架。
- 已有 `docs/` 但不是本工作流结构：把旧文档移动到 `docs/archive/legacy-docs-YYYYMMDD/`，再创建新结构。
- 已有本工作流结构：沿用，不覆盖已有文档。

旧文档归档后只作为历史参考，不作为当前实现依据。

初始化脚本：

```bash
scripts/init-dev-workflow.sh
```

Codex 快捷提示：

```text
/dev-workflow init
/dev-workflow 初始化项目
```

初始化并启用 Git hooks：

```bash
scripts/init-dev-workflow.sh --enable-hooks
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
3. `docs/index.md`
4. 当前任务关联的 `PRD / REQ / TASK / BUG / ADR / ACC`
5. `docs/design/` 和 `docs/ops/`
6. `docs/legacy/`
7. `docs/archive/`
8. 代码和测试

如果当前代码与 `docs/archive/` 中的旧文档冲突，以当前代码和当前链路文档为准。

## 四、命名规则

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

## 五、模板保护

`docs/**/TEMPLATE.md` 是母版，只能复制，不能作为任务文档直接填写。

新建文档时优先使用：

```bash
scripts/new-doc.sh TASK login-api
```

如果没有脚本，先复制对应 `TEMPLATE.md` 到带编号的新文件，再填写新文件。

日常开发、Bug 修复、验收、改版时，禁止直接修改任何 `TEMPLATE.md`。只有明确提出“修改模板”或“升级 dev-workflow 模板”时，才允许改模板。

## 六、最小闭环

### 新功能

必需：`PRD + REQ + TASK + ACC`

按需：`ADR / design / ops`

流程：

1. 写清 PRD 的目标、边界、验收标准。
2. 拆出 REQ 需求追踪矩阵。
3. 为每个 REQ 写验收方式和 TDD 计划。
4. 人工确认 REQ 矩阵。
5. 创建 TASK，明确改动范围。
6. 先写测试或手工验收项。
7. 确认测试失败或记录无法自动化原因。
8. 开发并验证。
9. 执行代码审查。
10. 更新 REQ / TASK 实际改动。
11. 创建 ACC 记录验收结果。
12. 更新 `index.md`。
13. 进入提交前人工审核。
14. 用户批准后提交代码和文档。

### PRD 改版 / 已有功能改版

必需：`PRD + REQ + TASK + ACC`

按需：`ADR / design / ops / LEGACY`

门禁：

- 没有 REQ 需求追踪矩阵，不编码。
- REQ 未经人工确认，不编码。
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
9. 确认后再创建 TASK 并进入 TDD 实现。

### Bug 修复

必需：`BUG + TASK + ACC`

按需：`ADR / design / ops`

流程：

1. 写清 BUG 现象、复现、根因。
2. 创建 TASK，明确修复范围。
3. 先写复现测试，或记录无法自动化原因。
4. 确认测试失败。
5. 修复并验证。
6. 执行代码审查。
7. 更新 BUG 修复结果。
8. 创建 ACC 记录验收结果。
9. 更新 `index.md`。
10. 进入提交前人工审核。
11. 用户批准后提交代码和文档。

### 维护 / 重构

必需：`TASK + ACC`

按需：`ADR / design / ops`

流程：

1. 创建 TASK，写清目标、非目标、改动范围。
2. 修改并验证。
3. 执行代码审查。
4. 创建 ACC。
5. 更新 `index.md`。
6. 进入提交前人工审核。
7. 用户批准后提交代码和文档。

## 七、什么时候写 ADR

满足任一条件才写：

- 改变架构或模块边界。
- 改变接口契约或数据模型。
- 做技术选型。
- 放弃过一个看似合理的方案，未来可能再次被提出。
- Bug 根因来自历史设计问题。

## 八、什么时候更新 ops

满足任一条件才更新：

- 部署方式变化。
- 配置项变化。
- 监控、告警、日志定位方式变化。
- 回滚方式变化。
- 应急处理步骤变化。

## 九、已有项目接入

首次接入只需要一份现状快照：

```text
legacy/LEGACY-20260528-160000-a7b8-current-system-summary.md
```

之后从当前任务开始追踪。当前改到哪个模块，就补哪个模块需要的历史，不做全量补档。

## 十、完成前检查

最终回复前必须确认：

- 关联文档已创建或更新。
- PRD / 改版任务已建立并确认 REQ 需求追踪矩阵。
- TASK 写明实际改动和验证结果。
- TASK 关联 REQ 或 BUG。
- TASK 或 ACC 写明代码审查结论。
- ACC 写明验收结论，并覆盖对应 REQ / BUG。
- 有测试框架时已优先使用 TDD；无法自动化时已记录原因和手工验收项。
- 必要的 ADR / design / ops 已处理，或明确“不需要”。
- `index.md` 已更新。
- 已列出待人工审核内容和待提交文件。

可执行脚本检查：

```bash
scripts/check-dev-docs.sh
```

Codex 快捷提示：

```text
/dev-workflow check
/dev-workflow 检查文档
```

## 十一、代码审查规则

代码审查是完成前门禁，但保持轻量：

- 小任务：执行自查，重点看需求偏离、无关改动、错误处理、测试缺口、文档同步。
- 复杂 / 高风险任务：使用 subagent 或人工做独立 review。
- 审查发现的问题必须先修复，或记录为遗留问题并关联后续 TASK。
- 审查结论必须回填到 TASK 或 ACC。

## 十二、TDD 规则

新功能、PRD 改版、Bug 修复默认优先使用 TDD：

- 编码前先写测试或手工验收项。
- 每个测试或验收项必须关联 REQ / BUG。
- 有测试框架时，先确认目标测试失败，再编码让测试通过。
- 已有功能改版时，先记录当前行为，再写 PRD 目标行为测试。
- 没有测试框架或不适合自动化时，必须在 REQ / TASK / ACC 里记录原因，并写手工验收项。

PRD 改版时，TDD 的输入必须来自 REQ 需求追踪矩阵，而不是模糊摘要。

## 十三、提交前人工审核

默认不自动提交代码。

完成开发、验证、代码审查和文档同步后，必须先进入人工审核：

- 列出代码变更摘要。
- 列出验证结果。
- 列出代码审查结论。
- 列出文档同步清单。
- 列出待提交文件。
- 等待用户明确回复“批准提交”或“确认提交”。

只有收到明确批准后，才提交代码和文档。

## 十四、提交规则

提交必须聚焦，只包含本次任务相关文件。

commit message 引用主编号：

```text
TASK-20260528-153500-b2c3 implement login api
BUG-20260528-154000-c3d4 fix token refresh failure
PRD-20260528-153000-a1b2 add user login workflow
```

## 十五、Subagent 使用规则

默认不使用 subagent。满足以下任一条件时才使用：

- 任务涉及多个独立模块。
- Bug 根因不明确。
- 需要并行调查代码路径、测试、文档或影响范围。
- 改动影响范围较大。
- 完成前需要独立 review 或 QA 检查。

subagent 的结论必须回填到对应文档：

- 调研结论写入 TASK。
- 根因证据写入 BUG。
- 验收结果写入 ACC。
- 被否决方案写入 TASK 或 ADR。

## 十六、Git hooks 门禁

`.githooks/` 是可选门禁模板，默认不自动启用。正式项目建议启用，临时项目可以不启用。

启用后，每次 `git commit` 都会执行轻量检查，防止忘记补文档：

- `pre-commit`：如果提交包含代码变更，必须同时包含 `docs/` 或 `AGENTS.md` 变更。
- `commit-msg`：提交信息必须包含 `PRD-20260528-153000-a1b2`、`TASK-20260528-153500-b2c3`、`BUG-20260528-154000-c3d4`、`ADR-20260528-154500-d4e5`、`ACC-20260528-155000-e5f6`、`OPS-20260528-155500-f6a7` 之一。

启用方式：

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit .githooks/commit-msg scripts/check-dev-workflow.sh
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
