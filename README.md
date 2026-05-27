# dev-workflow Skill

`dev-workflow` 是一个轻量开发工作流 Skill，用来让新功能、Bug 修复、维护和重构都能留下可追踪记录。

目标不是多写文档，而是确保每次变更都能回答：

- 为什么做？
- 改了什么？
- 怎么验证？
- 文档和提交在哪里？

## 一、安装

推荐把本仓库作为源码目录，再同步安装到 Codex：

```bash
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
rsync -a --delete --exclude .git ./ "$CODEX_HOME/skills/dev-workflow/"
```

安装后，Codex 可以通过以下提示触发：

```text
/dev-workflow init
/dev-workflow init --hooks
/dev-workflow check
/dev-workflow feature 用户登录功能
/dev-workflow bug 登录态过期后没有刷新
/dev-workflow refactor auth 模块
```

## 二、日常命令

### 初始化项目

```text
/dev-workflow init
```

会检查并补齐：

- `AGENTS.md`
- `docs/`
- `scripts/`
- `.githooks/`

如果项目已有旧 `docs/`，会归档到：

```text
docs/archive/legacy-docs-YYYYMMDD-HHMMSS/
```

### 初始化并启用 Git hooks

```text
/dev-workflow init --hooks
```

Git hooks 是项目级门禁，只对当前项目生效。正式项目建议启用，临时项目可以不启用。

### 检查文档

```text
/dev-workflow check
```

会运行项目内：

```bash
scripts/check-dev-docs.sh
```

检查必要目录、索引编号、任务验收关联，以及代码变更是否同步文档。

## 三、工作流闭环

默认最小闭环：

```text
新功能：PRD + TASK + ACC
Bug 修复：BUG + TASK + ACC
维护 / 重构：TASK + ACC
```

按需补充：

```text
ADR / design / ops / LEGACY
```

只有在影响架构、接口、数据模型、部署、监控、回滚或长期维护时，才补充这些文档。

## 四、完成标准

任务完成前必须确认：

- 关联文档已创建或更新。
- `TASK` 写明实际改动和验证结果。
- `TASK` 或 `ACC` 写明代码审查结论。
- `ACC` 写明验收结论。
- 必要的 `ADR / design / ops` 已处理，或明确不需要。
- `docs/index.md` 已更新。
- 已提交聚焦 commit。

没有完成文档同步和提交，不声明任务完成。

## 五、Git hooks

模板位于：

```text
assets/docs-template/.githooks/
```

启用方式：

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit .githooks/commit-msg scripts/check-dev-workflow.sh
```

关闭方式：

```bash
git config --unset core.hooksPath
```

Git hooks 只做最低限度检查：

- 代码变更必须伴随 `docs/` 或 `AGENTS.md` 变更。
- commit message 必须包含追踪编号，例如 `TASK-0001` 或 `BUG-0001`。

## 六、注意事项

- 不要为了“完整”补全所有历史。已有项目只从当前变更开始追踪。
- 小任务只写必要信息，不补无关文档。
- 旧文档归档后只作为历史参考，不作为当前实现依据。
- `ADR` 只记录重要决策，不要把每个小选择都写成 ADR。
- 代码审查默认先自查，复杂或高风险任务再使用 subagent / 人工独立 review。
- Git hooks 默认不自动启用，避免影响临时项目。
- subagent 默认不使用，只在复杂、并行、高风险或需要独立 review 时使用。

## 七、与 Superpowers 配合

`dev-workflow` 可以和 Superpowers 一起用：

```text
Superpowers 负责方法
dev-workflow 负责追踪和门禁
```

建议搭配：

- 需求澄清：`brainstorming` → 写入 PRD / TASK。
- 计划制定：`writing-plans` → 写入 TASK。
- Bug 定位：`systematic-debugging` → 写入 BUG。
- 实现：`test-driven-development` → 写入 TASK / ACC。
- 并行执行：`subagent-driven-development` → 结论写入 TASK / BUG / ADR / ACC。
- 完成验证：`verification-before-completion` → 写入 ACC。
- 代码审查：`requesting-code-review` → 写入 TASK / ACC。

dev-workflow 不替代 Superpowers，只负责建立追踪链路、沉淀关键结论、完成前检查文档和提交。

## 八、版本管理

当前版本见：

```text
VERSION
```

变更记录见：

```text
CHANGELOG.md
```

推荐版本规则：

- patch：修脚本 bug、改错字、优化提示。
- minor：新增命令、模板字段、检查规则。
- major：改变 workflow 行为或目录结构。

发布示例：

```bash
git add .
git commit -m "docs: update dev-workflow usage"
git tag v0.1.1
git push --tags
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
rsync -a --delete --exclude .git ./ "$CODEX_HOME/skills/dev-workflow/"
```
