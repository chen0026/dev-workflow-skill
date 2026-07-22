# dev-workflow

面向 Codex、Claude 等现代开发 Agent 的轻量工作流。它不替 Agent 规划或循环，只提供四件事：需求不跑偏、真实验证、一次人工审核、可追溯提交。

## 日常使用

直接描述任务即可：

```text
修复购物车无效价格商品仍能加入的问题，完成真实验证，先不要提交。
```

也可以显式调用：

```text
/dev-workflow 修复这个 Bug
/dev-workflow 根据 PRD 改版订单模块
/dev-workflow review 当前修改
/dev-workflow history 购物车价格校验
```

普通 Bug、小功能、重构和维护默认直接执行：调查 -> 实现 -> 测试 -> 真实验证 -> diff 审查。不会自动创建 REQ、TASK、BUG、CHG 或 ACC。

## 复杂任务

需求模糊、多模块、接口、数据迁移、权限、支付、部署或回滚等任务，优先使用 Codex/宿主原生 Plan mode。需要跨会话、换 Agent 或长期追溯时，只维护一个：

```text
docs/work/YYYY/MM/DEV-YYYYMMDD-HHMMSS-xxxx-short-title.md
```

DEV 同时记录目标、需求基线、关键决策、进度、验收证据和关联 commits，不再拆成多份配套文档。

## Agent 协作

- 主 Agent 负责决策、最终代码写入、验证汇总和完成声明。
- subagent 优先用于代码检索、影响分析、日志、测试和审查。
- 默认不进行开发前文件认领，不因其他线程计划修改文件而阻断。
- 同文件并行修改要提示风险；无法可靠拆分时联合验证并联合提交，或使用宿主原生隔离。
- Skill 不固定模型。复杂任务可使用当前强模型，扫描类 subagent 可使用更快模型。

## 提交

默认不自动 commit。Agent 必须先一次性展示：

- 待提交文件；
- 完整 commit message；
- 验证结果；
- 风险或未完成项。

回复“提交代码 / 确认提交 / 批准提交”后立即提交，不应重复确认。

`commit-scope.sh`仅保留给确实需要显式文件清单的特殊共享工作区，不在普通开发中自动运行，也不用于开发前锁文件。

## 初始化或迁移项目

在项目目录执行：

```text
/dev-workflow init
```

它会：

- 创建或更新简短的 `AGENTS.md`工作流区块；
- 删除旧版由 dev-workflow 写入的 TASK_KEY、track、manifest、harness 和 Loop 规则；
- 保留项目已有的其他 `AGENTS.md`内容；
- 确保 `.dev-workflow/`是本地忽略目录；
- 不移动已有 docs，不复制模板，不安装项目脚本。

可选启用轻量 Git hooks：

```text
/dev-workflow init --hooks
```

hooks 只检查已修改文档和提示 commit message 格式，不再根据 manifest 阻断提交。

老项目建议重新执行一次 init 完成规则迁移。旧文档不会被删除或搬迁。

如果 init 提示存在旧版项目脚本，审核后可清理：

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/scripts/clean-project-scripts.sh" --apply
```

清理脚本只处理已知的 dev-workflow 脚本名，并先支持不带 `--apply`的预览模式。

## 安装与同步

源码目录与 Codex 安装目录分离。开发完成后同步时排除 Git 元数据：

```bash
rsync -a --delete --exclude .git ./ "${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/"
```

不要在公开文档中写死个人用户名、绝对路径、仓库凭据或客户信息。

## 可选命令

```text
/dev-workflow check
/dev-workflow doctor
/dev-workflow version
/dev-workflow history <关键词|文件>
```

`check`和`doctor`按需使用，不要求每个任务执行。历史查询先看 Git diff，只有 Git 无法解释背景时才读取关联 DEV。
