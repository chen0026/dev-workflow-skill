# Details

## 项目接入

`/dev-workflow init` 只补齐 `AGENTS.md`、`docs/`、`.dev-workflow/` 忽略规则和 hooks 模板。默认不复制模板或脚本到项目。

旧项目可重复运行 init。已有 `docs/` 时不全量读取或强制迁移；只在结构冲突时归档旧文档。

## 定向调查

开始修改前确认：

- 真实用户入口或故障入口。
- 调用链、直接依赖和实际调用方。
- 计划修改文件、受影响但不修改的文件和回归测试。
- 现有公共能力能否复用或小幅扩展。

普通任务只需在内部计划或最终摘要体现，不创建实现地图文档。调查中发现高风险范围时才升级严格模式。

## ACTIVE 续作

- 任务选择顺序：用户给出的 exact ACTIVE > 当前对话绑定 > 唯一关键词匹配。
- 无绑定且存在多个候选时停止并请用户确认，不按最近时间或标题猜测。
- ACTIVE 未完成时持续更新原文件；已完成任务后续再改时新建 ACTIVE，不改写旧任务历史。
- 多线程使用不同 ACTIVE 和稳定的 `DEV_WORKFLOW_CONTEXT_ID`，不使用全局 `current-work.md`。

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/active-work.sh" current
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/active-work.sh" resolve 关键词
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/active-work.sh" start short-title
```

## 严格需求与一致性

REQ 至少包含：需求来源、现状、目标行为、范围外、影响面、验收项、测试和真实验证方式。

一致性链路简化为：

```text
PRD/REQ -> 验收项 -> 实现与测试 -> 真实证据 -> 人工审核
```

每个验收项必须能指向实现、测试或人工验证证据。存在缺口时不声称完成。

## 测试与真实验证

- 测试从用户行为、业务规则和失败风险推导，不只测当前实现细节。
- 覆盖主路径、边界、失败路径和受影响回归路径。
- mock、fixture、stub、MSW 和 Playwright route mock 可作为快速反馈，不得代替真实接口、真实后端、测试环境或人工实测。
- 真实环境暂时不可用时，明确标记未完成验收，不把 mock 说成降级验收。

## 代码审查与复用

完成前检查行为回归、遗漏调用方、重复实现、公共抽象边界、错误处理、性能和安全。

优先复用或扩展现有能力。只有至少两个真实调用方、业务语义一致且契约稳定时才抽公共能力。大文件按职责拆分，不按行数机械拆分。

## 人工审核和精确提交

默认不自动 commit。只在代码、测试、审查和真实验证完成，并得到用户明确批准后提交。

普通 Bug、功能完善和维护不建配套文档链。进入正式提交审核时，先运行 `new-doc.sh CHG short-title`，生成一个 `docs/changes/YYYY/MM/CHG-*.md`。

CHG 必须保持精简：YAML 只包含 `id / type / module / created_at / files / related`，正文只包含原因、变更、验证和影响。`files` 列出实际代码/测试文件，`related` 可关联旧 CHG / REQ / ADR；这些字段也是未来生成本地知识图谱的唯一输入。

CHG 和 commit message 只写工程事实，不写密钥、token、客户隐私、生产数据、内网凭据或其他敏感信息。

然后根据实际 diff 和验证结果生成以下 Git commit message：

```text
fix(scope): 简短描述用户可见变化

原因: 问题或需求背景
变更: 本次实际修改的行为和关键实现
验证: 已运行的测试与真实验证结果
影响: 影响范围、风险或“无已知风险”
```

- 类型使用 `fix / feat / refactor / chore / docs / test`，scope 使用稳定模块名。
- 记录必须来自实际 diff 和已完成验证，不照抄计划或推测。
- 人工审核同时确认待提交文件、CHG 和 commit message；任一变化都应重新确认。
- 临时提交或用户明确要求“不留文档”时，可在 commit 命令前设置 `DEV_WORKFLOW_SKIP_CHG=1`；结构化 commit message 仍保留。

开始提交审核时才创建临时清单：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" prepare TASK_KEY --all
# 共享工作区
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" prepare TASK_KEY -- current-file --other other-task-file
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" show
# 用户批准后
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" stage
git commit -m "..."
```

- `prepare` 必须完整分类 staged、unstaged 和 untracked 文件。
- 禁止用 `git add .`、`git add -u` 或 `git commit -am` 代替精确清单。
- 存在清单且包含代码时，pre-commit 核对暂存范围并要求恰好新增一个 CHG；不存在清单时 hooks 不强制普通人工提交走 skill 流程。
- 存在清单时 commit-msg 要求结构化摘要以及“原因/变更/验证/影响”四项；没有清单的普通人工提交只提醒。
- post-commit 只在存在清单时核对 HEAD 并清理。

历史追查先搜索精简 CHG，再读真实 Git diff：

```bash
rg -l '关键词' docs/changes
git log --all --grep='关键词' --regexp-ignore-case
git log --follow -- path/to/file
git show --stat --format=fuller COMMIT
```

如果需要查某行代码的引入原因，先用 `git blame` 找 commit，再用 `git show` 读取结构化记录和 diff。

## 按需工具

- harness：仅用于判断严格门禁、复杂切片或诊断项目接入。
- Loop：仅用于需求不清、验证失败或需要多轮可验证切片。
- 本地索引：仅在需要历史时调用 `search-dev-docs.sh`，不在每个任务前重建。
- subagent / Superpowers：按任务本身需要使用，结果默认只汇总到最终回复；续作或严格模式才写入 ACTIVE / REQ。
