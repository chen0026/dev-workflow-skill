# dev-workflow

轻量开发工作流：默认直接开发，只在跨会话或高风险时升级。普通 Bug 和功能不创建配套文档，提交时把修改内容写入 Git history。

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

- 开发过程新增文档 0 个；正式提交时新增 1 个精简 CHG。
- 不运行 harness、Loop 或索引。
- 最终只输出代码变更、验证结果、待提交文件和风险。

### 续作模式

仅在跨会话、换 agent、多人并行或需要交接时，使用一个 `docs/active/ACTIVE-*.md`。ACTIVE 只记录目标、进度、相关文件、下一步和验证结果。

### 严格模式

PRD 改版、多模块、接口契约、数据迁移、权限、支付、部署等高风险变更，编码前建立并人工确认 `REQ` 和验收矩阵。

## 真实验证

mock、fixture、stub、MSW 和 Playwright route mock 可用于快速反馈，但不能作为最终验收。最终结论必须来自真实后端、真实接口、真实运行环境或人工实测。

## 精确提交

默认不自动 commit。当用户请求提交时，agent 才会生成临时提交清单：

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/commit-scope.sh" prepare TASK_KEY --all
# 共享工作区要分类其他任务
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/commit-scope.sh" prepare TASK_KEY -- src/current.ts --other src/other.ts
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/commit-scope.sh" show
```

人工明确批准后才 stage 和 commit。存在清单时 hooks 会检查遗漏和混入；没有清单时，hooks 不强迫普通人工提交走 skill 流程。

### 提交即留痕

普通 Bug、功能完善和维护不新建 REQ、TASK、BUG 或 ACC。正式提交审核时只生成一个精简记录：

```text
docs/changes/YYYY/MM/CHG-YYYYMMDD-HHMMSS-xxxx-short-title.md
```

CHG 的 YAML 仅包含 `id / type / module / created_at / files / related`，正文仅包含原因、变更、验证和影响。它和代码同 commit，不维护共享索引，也不在普通任务中配套生成其他文档。

同时，agent 根据实际 diff 和验证结果自动起草 commit message：

```text
fix(dashboard): 修正未连接店铺时的 Step 2 跳转

原因: Dashboard 直接打开连接弹窗，与新的平台选择流程不一致。
变更: Step 2 改为跳转 /app/stores/connect，删除 Dashboard 中不再使用的弹窗分支。
验证: 定向测试通过；未连接、已连接和 Shopify 选择流程实测通过。
影响: 仅影响 Dashboard Step 2 导航，不改变店铺连接和授权逻辑。
```

用户审核的是“待提交文件 + CHG + commit message”。提交后可使用：

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
/dev-workflow commit prepare|show|stage|check|verify-head|clear
/dev-workflow history <关键词|文件>
```

`doctor / harness / Loop / search-dev-docs.sh` 都是诊断或复杂任务工具，不在每个任务中自动执行。

## Git hooks

Git hooks 是项目级配置：

```bash
git config core.hooksPath .githooks
```

- 有 commit manifest：pre-commit 检查精确范围，post-commit 核对 HEAD 并清理。
- 有 commit manifest 且包含代码：pre-commit 要求恰好新增一个完整 CHG。
- 有 commit manifest：commit-msg 必须包含结构化摘要和“原因/变更/验证/影响”四项记录。
- 无 commit manifest：允许普通人工提交。
- 仅当本次暂存了 `docs/` 或 `AGENTS.md` 时才检查文档。
- commit message 缺少追踪编号时只警告，不阻断。

临时提交或用户明确说“不留文档”时，agent 可在 commit 时设置 `DEV_WORKFLOW_SKIP_CHG=1`；commit message 仍保留结构化记录。

## 版本管理

源码在 `/Users/imc/work/skills/dev-workflow-skill`，安装副本在 `${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow`。只修改源码仓库，验证后再 `rsync`。
