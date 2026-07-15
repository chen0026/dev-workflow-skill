# Dev Workflow Lite

## 默认开发

普通 Bug、功能、重构和维护：

```text
定向调查 -> 实现 -> 测试 -> 真实验证 -> 代码审查 -> 人工批准提交
```

默认不创建任务文档，不运行 harness、Loop 或索引脚本。最终只列代码变更、验证结果、待提交文件和风险。

## 续作

跨会话、换 agent、多人并行或需要交接时，每个任务只使用一个 `active/ACTIVE-*.md`，记录：

- 目标与范围。
- 当前进度与相关文件。
- 下一步和阻塞项。
- 测试与真实验证结果。

选择顺序为 exact ACTIVE > 当前对话绑定 > 唯一关键词匹配。无绑定且多候选时请用户确认，不猜测。

## 严格模式

PRD 改版、多模块、接口契约、数据迁移、权限、支付、部署、回滚或其他高风险变更，编码前建立一个 `work/YYYY/MM/DEV-*.md`，包含：

- 需求来源、现状、目标行为和范围外。
- 影响面、验收项、测试和真实验证方式。
- `编码前确认：已确认`。

DEV 的需求基线和验收矩阵未经人工确认时不编码。

## 验证和审查

- 测试覆盖主路径、边界、失败路径和受影响回归路径。
- mock、fixture、stub、MSW 和 Playwright route mock 不得作为最终验收。
- 完成前检查遗漏调用方、行为回归、重复实现、公共抽象边界、性能和安全。
- 只在不注释难以理解的关键业务逻辑处补简短中文注释。

## 精确提交

Agent 在本线程首次修改文件前后台增量记录，用户无须操作：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" track TASK_KEY -- current-file
```

文件已被其他线程记录时在编码前停止。旧对话可在请求提交时才创建任务独立清单：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" prepare TASK_KEY --all
# 共享工作区只列本任务文件
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" prepare TASK_KEY -- current-file optional-DEV-file
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" show TASK_KEY
```

首次询问前一次性展示文件范围、完整 commit message 和验证结果；使用 DEV 时再展示 DEV 变化。用户确认一次后立即提交，不得重复确认。脚本使用 `git commit --only`，其他任务暂存文件保持不变。

普通 Bug、功能、重构和维护不新建 CHG、REQ、TASK、BUG 或 ACC，直接使用结构化 Git commit 留痕。复杂任务只维护一个 DEV。

然后根据实际 diff 起草并展示 commit message：

```text
fix/feat(scope): 用户可见摘要

原因: 问题或需求背景
变更: 实际修改的行为和关键实现
验证: 已运行测试和真实验证
影响: 影响范围与风险
```

用户一次确认文件范围、完整 commit message、验证结果和可选 DEV 变化后立即 commit。历史先通过 `git log --follow -- FILE`、`git blame` 和 `git show` 追查真实 diff。
存在精确提交清单时，pre-commit 核对文件范围，commit-msg 会阻断缺少上述四项的记录；普通人工提交不强制。
只有 commit 成功、HEAD 变化、提交文件与本线程记录一致且这些文件无残留时，才能报告提交成功。

## 索引与命名

只在需要历史时使用 Git 或运行 `search-dev-docs.sh 关键词`，不在每个任务前重建索引。`.dev-workflow/` 和 `docs/index.md` 不提交。

文档命名：

```text
TYPE-YYYYMMDD-HHMMSS-xxxx-short-title.md
```

`xxxx` 是随机短 ID，避免多电脑、多分支同秒冲突。
