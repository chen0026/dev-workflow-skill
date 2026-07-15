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

## DEV 生命周期与一致性

严格任务只使用一个 DEV，包含需求基线、实现计划、问题与决策、验收矩阵、执行进度和 Git 记录。需求基线确认后不得静默覆盖；变化时追加修订说明。

一致性链路简化为：

```text
PRD/DEV -> 验收项 -> 实现与测试 -> 真实证据 -> 人工审核
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

每个线程使用稳定 TASK_KEY，并在首次修改文件前由 Agent 后台增量记录：

```bash
commit-scope.sh track TASK_KEY -- path/to/file
```

- 用户不需要记忆或执行 track；Agent 在计划修改和后续发现文件时调用。
- track 只记录本线程触碰的文件，不要求分类整个工作区；已被其他任务记录的文件会在编码前阻断。
- 同一线程后续 prepare 必须与已有记录取并集，不能覆盖或缩小文件范围。

普通 Bug、功能完善和维护不创建 CHG 或其他任务文档，结构化 commit message 是稳定修改记录。复杂任务的 DEV 可在重要节点追加关联 commit，不要求每个 commit 都修改 DEV。

DEV 和 commit message 只写工程事实，不写密钥、token、客户隐私、生产数据、内网凭据或其他敏感信息。

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
- 首次询问确认前必须一次性展示待提交文件、完整 commit message 和验证结果；使用 DEV 时再展示 DEV 变化，不分多轮补充。
- 用户在完整审核包后回复“提交代码 / 确认提交 / 批准提交”即完成最终授权；精确 stage、hooks 和 commit 都属于同一次授权，禁止再次询问。
- 只有授权后文件范围、DEV、commit message 或验证结论实际变化时，授权才失效；展示变化后重新确认一次。

开始提交审核时才创建临时清单：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" prepare TASK_KEY --all
# 共享工作区
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" prepare TASK_KEY -- current-file optional-DEV-file
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" show TASK_KEY
# 用户批准后
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/commit-scope.sh" commit TASK_KEY -m "..."
```

- `prepare` 只列本任务文件；每个任务保存到 `.dev-workflow/commits/TASK_KEY.txt`，不再分类其他任务文件。
- 禁止用 `git add .`、`git add -u` 或 `git commit -am` 代替精确清单。
- `commit` 使用 `git commit --only`，因此其他任务已暂存文件保持不变；不同任务清单包含同一文件时阻断。
- 存在清单时 pre-commit 只核对文件范围；不存在清单时 hooks 不强制普通人工提交走 skill 流程。
- 存在清单时 commit-msg 要求结构化摘要以及“原因/变更/验证/影响”四项；没有清单的普通人工提交只提醒。
- post-commit 只在存在清单时核对 HEAD 并清理。
- 只有 commit 返回成功、HEAD 从提交前基线发生变化、HEAD 文件与清单完全一致且本线程文件无残留时，才能回复“提交成功”。

历史追查先读真实 Git diff，再按需读取 DEV 或旧文档：

```bash
git log --all --grep='关键词' --regexp-ignore-case
git log --follow -- path/to/file
git show --stat --format=fuller COMMIT
rg -l '关键词' docs/work docs/changes 2>/dev/null
```

如果需要查某行代码的引入原因，先用 `git blame` 找 commit，再用 `git show` 读取结构化记录和 diff。

## 按需工具

- harness：仅用于判断严格门禁、复杂切片或诊断项目接入。
- Loop：仅用于需求不清、验证失败或需要多轮可验证切片。
- 本地索引：仅在需要历史时调用 `search-dev-docs.sh`，不在每个任务前重建。
- subagent / Superpowers：按任务本身需要使用，结果默认只汇总到最终回复；续作或严格模式才写入 ACTIVE / DEV。
