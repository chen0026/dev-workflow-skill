# 项目文档

本目录用于沉淀项目开发历史。目标是关键变更可追溯，小任务不被文档拖住。

## 目录导航

| 目录 | 放什么 | 谁来写 |
|------|--------|--------|
| `workflow.md` | 开发工作流、门禁规则、完成标准 | 开发负责人 |
| `index.md` | 人类入口说明；机器索引由脚本生成 | 开发 |
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
5. **验收就近记录**：quick 写最终摘要，standard 写主记录，strict 才单独写 ACC
6. **提交前必须人工审核**：验证和文档同步通过后，先等待人工审核；用户批准后才提交
7. **索引可重建**：多分支开发时不要手工维护共享索引，使用本地索引脚本检索

## Git hooks

`.githooks/` 是可选门禁模板，默认不自动启用。正式项目建议启用，临时项目可以不启用。

启用方式见 [`workflow.md`](workflow.md) 的“Git hooks 门禁”。

## 脚本

- `scripts/init-dev-workflow.sh`：初始化 `AGENTS.md`、`docs/`、`.githooks/` 和检查脚本。
- `scripts/check-dev-docs.sh`：检查必要目录、主记录关键字段，并重建本地索引。
- `scripts/check-dev-workflow.sh`：供 Git hooks 调用的提交门禁脚本。
- `scripts/new-doc-id.sh`：生成时间戳文档编号，例如 `scripts/new-doc-id.sh TASK login-api`。
- `scripts/new-doc.sh`：从模板创建新文档，例如 `scripts/new-doc.sh TASK login-api`。
- `scripts/clean-templates.sh`：清理旧项目中已经复制进去的 `docs/**/TEMPLATE.md`，默认只预览。
- `scripts/session-state.sh`：管理长任务临时状态文件，减少上下文占用。
- `scripts/reindex-dev-docs.sh`：生成 `.dev-workflow/index/docs.jsonl` 本地机器索引。
- `scripts/search-dev-docs.sh`：按关键词检索本地文档索引，避免全量读取历史。

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
- quick 小改：默认不写正式文档，只在最终回复摘要
- standard Bug：写一个 BUG 主记录
- standard 功能 / 维护：写一个 TASK 主记录
- strict PRD 改版 / 高风险新功能：先写 REQ 需求追踪矩阵，人工确认后再编码
- 合并 PR 前：按流程级别更新对应主记录和必要架构文档
- 修复高风险 Bug 后：必要时写完整 Bug 复盘和 ACC
- 需求变更时：在原文档追加变更记录，必要时新建 ADR
- 技术选型时：写 ADR
- 每次任务完成前：按流程级别补齐主记录或 strict 文档链路，并重建本地索引

## 执行策略

- 默认自动分级：从 `quick` 起步，按风险升级到 `standard / strict`，不要求用户手动选择。
- quick 默认不创建正式文档；standard 默认一个主记录；strict 才拆完整链路。
- PRD、产品文档、现有功能改版、多模块、高风险、接口/数据/权限/支付/订单/登录/部署变化，自动使用 `strict`。
- 分级优先级：硬门禁 > 风险自动升级 > 用户指定 > 默认 quick。
- 默认禁止全量读取历史文档；先用 `search-dev-docs.sh` 检索候选，再按当前任务读取相关文档。

## 本地索引和多分支合并

`docs/index.md` 不再作为人工维护的总索引。多电脑、多分支并行时，每个任务只新增或更新自己的文档，完成前运行：

```bash
scripts/reindex-dev-docs.sh
```

机器索引写入：

```text
.dev-workflow/index/docs.jsonl
```

该目录默认加入 `.gitignore`，不提交。这样合并代码时不会因为所有分支都修改同一个索引文件而频繁冲突。

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
