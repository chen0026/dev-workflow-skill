# dev-workflow

轻量开发工作流：普通修改只用结构化 Git history，复杂任务只维护一个 DEV 生命周期文档。

## 安装

推荐把本仓库作为源码目录，用 `rsync` 同步到 Codex：

```bash
cd /Users/imc/work/skills/dev-workflow-skill
rsync -a --delete --exclude .git ./ "${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/"
```

该命令只复制 skill 仓库内容，不会上传项目代码、对话或本地文档。

## 日常使用

直接描述任务即可：

```text
修复文件夹重命名问题
增加会员过期提醒
根据这份 PRD 改版订单模块
继续 ACTIVE-... 的任务
提交代码
```

普通 Bug、功能、重构和维护会直接调查、实现、测试和审查，默认不生成开发文档。

## 三种路径

### 默认开发

适用于大多数日常任务：

```text
定向调查 -> 实现 -> 测试 -> 真实验证 -> 代码审查 -> 人工批准提交
```

- 普通任务和正式提交都不强制新增文档。
- 不运行 harness、Loop 或索引。
- 最终只输出代码变更、验证结果、待提交文件和风险。

### 续作模式

仅在跨会话、换 agent、多人并行或需要交接时，使用一个 `docs/active/ACTIVE-*.md`。ACTIVE 只记录目标、进度、相关文件、下一步和验证结果。

### 严格模式

PRD 改版、多模块、接口契约、数据迁移、权限、支付、部署等高风险变更，只建立一个 `docs/work/YYYY/MM/DEV-*.md`，在同一文件中维护需求、计划、问题、进度和验收。

## 真实验证

mock、fixture、stub、MSW 和 Playwright route mock 可用于快速反馈，但不能作为最终验收。最终结论必须来自真实后端、真实接口、真实运行环境或人工实测。

## 精确提交

每个线程使用稳定 TASK_KEY。Agent 在修改文件前后台增量记录本线程文件，用户无须操作：

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/commit-scope.sh" track TASK_KEY -- src/current.ts
```

后续发现文件继续 track；同一文件已被其他线程记录时在编码前停止。旧对话仍可在请求提交时生成任务独立清单：

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/commit-scope.sh" prepare TASK_KEY --all
# 共享工作区只列本任务文件，不需要列其他任务
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/commit-scope.sh" prepare TASK_KEY -- src/current.ts
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/commit-scope.sh" show TASK_KEY
```

Agent 必须一次性展示文件范围、完整 commit message 和验证结果；使用 DEV 时再展示 DEV 变化。用户确认后立即提交，不得重复确认。脚本通过 `git commit --only`只提交当前任务文件。

正常情况下仍由当前线程直接提交，不要求用户寻找统一收口线程。只有 commit 成功、HEAD 变化、提交文件与本线程记录完全一致且无残留时，才能报告提交成功。

### Git 留痕

普通 Bug、功能完善、重构和维护不创建 CHG、REQ、TASK、BUG 或 ACC。Agent 根据实际 diff 和验证结果起草结构化 commit message：

```text
fix(dashboard): 修正未连接店铺时的 Step 2 跳转

原因: Dashboard 直接打开连接弹窗，与新的平台选择流程不一致。
变更: Step 2 改为跳转 /app/stores/connect，删除 Dashboard 中不再使用的弹窗分支。
验证: 定向测试通过；未连接、已连接和 Shopify 选择流程实测通过。
影响: 仅影响 Dashboard Step 2 导航，不改变店铺连接和授权逻辑。
```

用户审核的是“待提交文件 + commit message + 验证结果”；复杂任务再包含 DEV 变化。提交后可使用：

```bash
rg -l '关键词' docs/changes
git log --all --grep='关键词' --regexp-ignore-case
git log --follow -- path/to/file
git blame path/to/file
git show COMMIT
```

## 项目初始化

```text
/dev-workflow init
/dev-workflow init --hooks
```

默认创建或补齐：

- `AGENTS.md`
- `docs/`
- `.githooks/`
- `.dev-workflow/` 忽略规则

默认不复制模板或通用脚本到项目。旧项目可重复执行 init，它会追加 Lite 覆盖规则，使旧 Harness-first 约束失效。

## 按需命令

```text
/dev-workflow version
/dev-workflow doctor
/dev-workflow check
/dev-workflow active list|start|current|resolve|finish
/dev-workflow loop start|step|verify|decide|status
/dev-workflow commit track|prepare|show|list|stage|check|commit|verify-head|clear
/dev-workflow history <关键词|文件>
```

`doctor / harness / Loop / search-dev-docs.sh` 都是诊断或复杂任务工具，不在每个任务中自动执行。

## Git hooks

Git hooks 是项目级配置：

```bash
git config core.hooksPath .githooks
```

- 有任务 manifest：pre-commit 检查当前任务范围，post-commit 只清理当前任务清单。
- 有任务 manifest：pre-commit 只核对当前任务文件范围。
- 有任务 manifest：commit-msg 必须包含结构化摘要和“原因/变更/验证/影响”四项记录。
- 多个任务并行时必须使用 `commit-scope.sh commit TASK_KEY ...`，直接 `git commit` 会因任务上下文不明确而阻断。
- 无 commit manifest：允许普通人工提交。
- 仅当本次暂存了 `docs/` 或 `AGENTS.md` 时才检查文档。
- commit message 缺少追踪编号时只警告，不阻断。

旧 CHG、REQ、TASK、BUG、ACC 文件继续保留和检索，但新任务不再默认创建。

## 版本管理

源码在 `/Users/imc/work/skills/dev-workflow-skill`，安装副本在 `${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow`。只修改源码仓库，验证后再 `rsync`。
