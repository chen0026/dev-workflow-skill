# 项目文档

本目录用于沉淀项目开发历史，保证每次新功能、Bug 修复、重构、维护都能追踪到需求、任务、决策、验收、人工审核和提交记录。

## 目录导航

| 目录 | 放什么 | 谁来写 |
|------|--------|--------|
| `workflow.md` | 开发工作流、门禁规则、完成标准 | 开发负责人 |
| `index.md` | PRD / REQ / TASK / BUG / ADR / ACC 总索引 | 开发 |
| `prd/` | 产品需求文档，含变更记录 | 产品 + 开发补充 |
| `requirements/` | PRD 需求项追踪矩阵，连接原文、任务、验收和测试 | 产品 + 开发 |
| `design/` | 架构设计、技术方案 | 开发 |
| `design/decisions/` | ADR，重要技术决策记录 | 开发 |
| `tasks/` | 任务拆解、开发日志、AI 协作记录 | 开发 |
| `bugs/` | Bug 复盘、根因分析 | 开发 |
| `acceptance/` | 验收记录、验证结果、完成结论 | 开发 / 测试 |
| `ops/` | 部署、监控、应急手册 | 开发 / 运维 |
| `legacy/` | 已有项目接入时的现状快照和补录记录 | 开发 |
| `archive/` | 接入 workflow 前的旧文档归档，只作历史参考 | 开发 |

## 文档维护原则

1. **代码改了，文档跟着改**：跟随 PR 一起提交
2. **决策只追加不覆盖**：ADR 是历史记录，不是当前状态
3. **PRD 变更走变更记录**：保留原始版本，追加变更日志
4. **AI 协作有痕迹**：关键 prompt 和决策过程要记录
5. **完成必须有验收**：没有 ACC 验收记录，不算任务完成
6. **提交前必须人工审核**：验证和文档同步通过后，先等待人工审核；用户批准后才提交
7. **优先级排序**：ADR > Bug 复盘 > 任务文档 > 验收文档 > 其他

## Git hooks

`.githooks/` 是可选门禁模板，默认不自动启用。正式项目建议启用，临时项目可以不启用。

启用方式见 [`workflow.md`](workflow.md) 的“Git hooks 门禁”。

## 脚本

- `scripts/init-dev-workflow.sh`：初始化 `AGENTS.md`、`docs/`、`.githooks/` 和检查脚本。
- `scripts/check-dev-docs.sh`：检查必要目录、索引编号、任务验收关联和代码变更是否同步文档。
- `scripts/check-dev-workflow.sh`：供 Git hooks 调用的提交门禁脚本。
- `scripts/new-doc-id.sh`：生成时间戳文档编号，例如 `scripts/new-doc-id.sh TASK login-api`。
- `scripts/new-doc.sh`：从模板创建新文档，例如 `scripts/new-doc.sh TASK login-api`。
- `scripts/clean-templates.sh`：清理旧项目中已经复制进去的 `docs/**/TEMPLATE.md`，默认只预览。
- `scripts/session-state.sh`：管理长任务临时状态文件，减少上下文占用。

也可以让 Codex 使用快捷提示：

```text
/dev-workflow init
/dev-workflow init --hooks
/dev-workflow check
/dev-workflow clean-templates
/dev-workflow 初始化项目
/dev-workflow 初始化项目并启用 hooks
/dev-workflow 检查文档
```

## 何时写文档

- 项目首次接入：检查 `AGENTS.md` 和 `docs/`，必要时归档旧文档并初始化目录
- 启动新模块：写 PRD 理解 + 任务拆解 + 关键 ADR
- PRD 改版 / 新功能：先写 REQ 需求追踪矩阵，人工确认后再编码
- 合并 PR 前：更新对应的任务文档和架构文档
- 修复 Bug 后：写 Bug 复盘
- 需求变更时：在原文档追加变更记录，必要时新建 ADR
- 技术选型时：写 ADR
- 每次任务完成前：补齐 TASK / BUG / ADR / ACC / ops，并更新 `index.md`

## 执行策略

- 默认自动分级：`quick / standard / strict`，不要求用户手动选择。
- PRD、产品文档、现有功能改版、多模块、高风险、接口/数据/权限/支付/订单/登录/部署变化，自动使用 `strict`。
- 分级优先级：硬门禁 > 风险自动升级 > 用户指定 > 默认判断。
- 默认禁止全量读取历史文档；先读 `index.md`，再按当前任务读取相关文档。

## 命名规范

统一使用 `类型-创建时间-随机码-英文短标题.md`：

```text
TYPE-YYYYMMDD-HHMMSS-XXXX-short-title.md
```

- `YYYYMMDD-HHMMSS` 使用创建文档时的本地时间。
- `XXXX` 使用 4 位小写随机码，避免多电脑、多分支同秒创建时冲突。
- 合并后按文件名即可看出大致创建顺序。

- `prd/PRD-20260528-153000-a1b2-user-login.md`
- `requirements/REQ-20260529-101500-a1b2-member-revamp.md`
- `tasks/TASK-20260528-153500-b2c3-login-api.md`
- `bugs/BUG-20260528-154000-c3d4-token-expired.md`
- `design/decisions/ADR-20260528-154500-d4e5-use-jwt-auth.md`
- `acceptance/ACC-20260528-155000-e5f6-user-login.md`
- `legacy/LEGACY-20260528-160000-a7b8-current-system-summary.md`

## 模板保护

`docs/**/TEMPLATE.md` 是母版，只能复制，不能作为任务文档直接填写。

默认初始化不会把模板复制到项目目录。模板保存在已安装的 dev-workflow Skill 中，`scripts/new-doc.sh` 会从 Skill 模板创建新文档。

如果项目需要自包含模板，使用：

```bash
scripts/init-dev-workflow.sh --with-templates
```

新建文档时使用：

```bash
scripts/new-doc.sh TASK login-api
```

只有明确提出“修改模板”或“升级 dev-workflow 模板”时，才允许改 `TEMPLATE.md`。
