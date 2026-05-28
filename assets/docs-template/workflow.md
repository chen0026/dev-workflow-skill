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
4. 当前任务关联的 `PRD / TASK / BUG / ADR / ACC`
5. `docs/design/` 和 `docs/ops/`
6. `docs/legacy/`
7. `docs/archive/`
8. 代码和测试

如果当前代码与 `docs/archive/` 中的旧文档冲突，以当前代码和当前链路文档为准。

## 四、最小闭环

### 新功能

必需：`PRD + TASK + ACC`

按需：`ADR / design / ops`

流程：

1. 写清 PRD 的目标、边界、验收标准。
2. 创建 TASK，明确改动范围。
3. 开发并验证。
4. 执行代码审查。
5. 更新 TASK 实际改动。
6. 创建 ACC 记录验收结果。
7. 更新 `index.md`。
8. 进入提交前人工审核。
9. 用户批准后提交代码和文档。

### Bug 修复

必需：`BUG + TASK + ACC`

按需：`ADR / design / ops`

流程：

1. 写清 BUG 现象、复现、根因。
2. 创建 TASK，明确修复范围。
3. 修复并验证。
4. 执行代码审查。
5. 更新 BUG 修复结果。
6. 创建 ACC 记录验收结果。
7. 更新 `index.md`。
8. 进入提交前人工审核。
9. 用户批准后提交代码和文档。

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

## 五、什么时候写 ADR

满足任一条件才写：

- 改变架构或模块边界。
- 改变接口契约或数据模型。
- 做技术选型。
- 放弃过一个看似合理的方案，未来可能再次被提出。
- Bug 根因来自历史设计问题。

## 六、什么时候更新 ops

满足任一条件才更新：

- 部署方式变化。
- 配置项变化。
- 监控、告警、日志定位方式变化。
- 回滚方式变化。
- 应急处理步骤变化。

## 七、已有项目接入

首次接入只需要一份现状快照：

```text
legacy/LEGACY-0001-current-system-summary.md
```

之后从当前任务开始追踪。当前改到哪个模块，就补哪个模块需要的历史，不做全量补档。

## 八、完成前检查

最终回复前必须确认：

- 关联文档已创建或更新。
- TASK 写明实际改动和验证结果。
- TASK 或 ACC 写明代码审查结论。
- ACC 写明验收结论。
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

## 九、代码审查规则

代码审查是完成前门禁，但保持轻量：

- 小任务：执行自查，重点看需求偏离、无关改动、错误处理、测试缺口、文档同步。
- 复杂 / 高风险任务：使用 subagent 或人工做独立 review。
- 审查发现的问题必须先修复，或记录为遗留问题并关联后续 TASK。
- 审查结论必须回填到 TASK 或 ACC。

## 十、提交前人工审核

默认不自动提交代码。

完成开发、验证、代码审查和文档同步后，必须先进入人工审核：

- 列出代码变更摘要。
- 列出验证结果。
- 列出代码审查结论。
- 列出文档同步清单。
- 列出待提交文件。
- 等待用户明确回复“批准提交”或“确认提交”。

只有收到明确批准后，才提交代码和文档。

## 十一、提交规则

提交必须聚焦，只包含本次任务相关文件。

commit message 引用主编号：

```text
TASK-0001 implement login api
BUG-0001 fix token refresh failure
PRD-0001 add user login workflow
```

## 十二、Subagent 使用规则

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

## 十三、Git hooks 门禁

`.githooks/` 是可选门禁模板，默认不自动启用。正式项目建议启用，临时项目可以不启用。

启用后，每次 `git commit` 都会执行轻量检查，防止忘记补文档：

- `pre-commit`：如果提交包含代码变更，必须同时包含 `docs/` 或 `AGENTS.md` 变更。
- `commit-msg`：提交信息必须包含 `PRD-0001`、`TASK-0001`、`BUG-0001`、`ADR-0001`、`ACC-0001`、`OPS-0001` 之一。

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
