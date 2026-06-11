# dev-workflow Skill

`dev-workflow` 是一个轻量开发工作流 Skill，用来让新功能、Bug 修复、维护和重构都能留下可追踪记录。

目标不是多写文档，而是确保每次变更都能回答：

- 为什么做？
- 改了什么？
- 怎么验证？
- 是否通过人工审核？
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
/dev-workflow clean-templates
/dev-workflow version
/dev-workflow doctor
修复登录态过期后没有刷新
开发用户登录功能
根据 PRD 改版文件管理器
重构 auth 模块
```

开发任务不需要记子命令。只要正常描述 Bug、功能、重构、维护、PRD 或改版任务，agent 会自动运行 harness。

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
- `.dev-workflow/index/`

默认不会把 `TEMPLATE.md` 复制到项目目录。模板保存在已安装的 Skill 中，`scripts/new-doc.sh` 会从 Skill 模板创建新文档。

老项目升级时也可以再次运行 `/dev-workflow init`。它会补齐缺失结构，并强制更新 `scripts/dev-workflow-harness.sh`、`scripts/search-dev-docs.sh`、`scripts/reindex-dev-docs.sh`，但不会覆盖其它已有脚本和文档。

如果项目已有旧 `docs/`，会归档到：

```text
docs/archive/legacy-docs-YYYYMMDD-HHMMSS/
```

### 初始化并启用 Git hooks

```text
/dev-workflow init --hooks
```

Git hooks 是项目级门禁，只对当前项目生效。正式项目建议启用，临时项目可以不启用。

### 初始化并复制模板

```text
/dev-workflow init --with-templates
```

只有项目需要完全自包含模板时才使用。一般项目不建议复制模板，避免误改 `TEMPLATE.md`。

### 检查文档

```text
/dev-workflow check
```

会运行项目内：

```bash
scripts/check-dev-docs.sh
```

检查必要目录、任务验收关联、代码变更是否同步文档，并重建本地索引。

### Harness 检查

```bash
scripts/dev-workflow-harness.sh version
scripts/dev-workflow-harness.sh doctor
scripts/dev-workflow-harness.sh classify "修复文件夹重命名 bug"
scripts/dev-workflow-harness.sh run "修复文件夹重命名 bug"
scripts/dev-workflow-harness.sh report "修复文件夹重命名 bug"
scripts/dev-workflow-harness.sh verify "修复文件夹重命名 bug"
scripts/dev-workflow-harness.sh check
```

`doctor` 用来检查当前项目是否接入完整、项目内 harness 是否过期、hooks 是否启用、索引是否存在。重点看 `upgrade_needed / missing_required / doctor_status / next_action`。

`run` 是推荐入口，会输出 `flow / flow_reason / docs_allowed / next_action / verify_command / check_command`。`verify` 检查需求追踪、验证证据、文档预算和提交前人工审核状态，重点看 `requirement_status / evidence_status / machine_gate / requirement_match`。

### 清理旧模板

```text
/dev-workflow clean-templates
```

默认只预览项目内的 `docs/**/TEMPLATE.md`，不会删除。

确认后执行：

```bash
scripts/clean-templates.sh --apply
```

## 三、工作流闭环

自然语言任务默认闭环：

```text
用户描述任务
  -> harness run
  -> 按 flow 执行
  -> harness verify/check
  -> 人工审核需求一致性
  -> 用户确认后才提交
```

默认最小留痕：

```text
quick：默认不创建正式文档，只输出摘要
standard Bug：一个 BUG 主记录
standard 功能 / 维护：一个 TASK 主记录
strict PRD / 改版：PRD + REQ + TASK + ACC
```

按需补充：

```text
ADR / design / ops / LEGACY
```

只有在影响架构、接口、数据模型、部署、监控、回滚或长期维护时，才补充这些文档。

standard 的验证、代码审查、验收结论写在同一个 TASK 或 BUG 里，不默认单独创建 ACC。

## 四、省 token 策略

`dev-workflow` 默认自动分级，不要求用户手动选择。默认从 `quick` 起步，按风险升级：

- `quick`：文案、样式、小配置、小功能、小 Bug、单文件或低风险改动。
- `standard`：普通 Bug、普通功能调整、单模块功能。
- `strict`：PRD、产品文档、现有功能改版、多模块、高风险、接口/数据/权限/支付/订单/登录/部署变化。

优先级：

```text
硬门禁 > 风险自动升级 > 文档预算 > 用户指定 > 默认 quick
```

用户指定 `quick` 时，如果检测到 PRD、改版、接口、数据或核心链路风险，会自动升级并说明原因。

quick 不强制写文档；standard 默认一个主记录；strict 才拆完整链路。

文档预算：

- quick：新增文档 0 个。
- standard：新增文档最多 1 个，Bug 用 BUG，功能 / 维护用 TASK。
- strict：才允许完整链路。
- 普通任务禁止同时新建 `TASK + BUG + ACC`，不手工更新或提交 `docs/index.md`。

默认禁止全量读取历史文档：先读 `AGENTS.md`、`docs/workflow.md`，再用 `scripts/search-dev-docs.sh` 查候选文档。

`SKILL.md` 只保留硬规则，详细规则按需读取 `references/`。

长任务可使用 `.dev-workflow/session/*-working.json` 保存结构化状态，减少上下文占用。完成后确认已合并到正式文档再清理。

本地文档索引用 `.dev-workflow/index/docs.jsonl`，默认不提交。日常直接搜索即可；索引缺失或真实文档更新时，搜索脚本会自动重建：

```bash
scripts/search-dev-docs.sh login
```

需要手动重建或生成临时人类可读索引时，再执行：

```bash
scripts/reindex-dev-docs.sh
scripts/reindex-dev-docs.sh --write-md
```

`docs/index.md` 只是可选的人类可读生成文件，默认加入 `.gitignore`，不再作为每次任务必须手工更新的共享索引，避免多分支合并冲突。

已经被 Git 跟踪的旧项目，可执行：

```bash
git rm --cached docs/index.md
```

## 五、命名规则

新文档统一使用时间戳编号，避免多电脑、多分支并行时产生序号冲突：

```text
TYPE-YYYYMMDD-HHMMSS-XXXX-short-title.md
```

示例：

```text
PRD-20260528-153000-a1b2-user-login.md
TASK-20260528-153500-b2c3-login-api.md
BUG-20260528-154000-c3d4-token-expired.md
ACC-20260528-155000-e5f6-user-login.md
REQ-20260529-101500-a1b2-member-revamp.md
```

说明：

- `YYYYMMDD-HHMMSS` 使用创建文档时的本地时间。
- `XXXX` 使用 4 位小写随机码。
- 合并后按文件名即可看出大致创建顺序。
- 旧项目中的 `TASK-0001` 这类编号继续有效，但新文档一律使用时间戳编号。

可以用脚本生成编号：

```bash
scripts/new-doc-id.sh TASK login-api
```

也可以直接从模板创建新文档：

```bash
scripts/new-doc.sh TASK login-api
```

`docs/**/TEMPLATE.md` 是母版。日常任务只能复制模板创建新文档，禁止直接填写或修改 `TEMPLATE.md`；只有明确要求修改模板时例外。

默认初始化不把模板放进项目目录。需要项目自包含模板时，使用：

```bash
scripts/init-dev-workflow.sh --with-templates
```

## 六、PRD 追踪矩阵和 TDD

当任务来自 PRD、新功能、现有功能改版或产品文档时，不能直接编码。

必须先建立 REQ 需求追踪矩阵：

```text
| 需求项 | PRD 原文依据 | 当前实现 | 目标行为 | 关联任务 | 验收方式 | 测试状态 | 状态 |
```

门禁：

- 没有 REQ，不编码。
- REQ 未经人工确认，不编码。
- 每个 TASK 必须关联一个或多个 REQ。
- 每个 ACC 必须验收对应 REQ。
- 有测试框架时优先 TDD；没有测试框架时记录原因并写手工验收项。

## 七、完成标准

任务完成前必须确认：

- 关联文档已创建或更新。
- quick 可无正式文档，最终回复必须写摘要。
- PRD / 改版任务已建立并确认 REQ 需求追踪矩阵。
- `TASK` 写明实际改动和验证结果。
- `TASK` 或 `BUG` 写明代码审查结论和验收结论。
- strict 的 `ACC` 写明验收结论，并覆盖对应 REQ / BUG。
- 有测试框架时已优先使用 TDD；无法自动化时已记录原因和手工验收项。
- 必要的 `ADR / design / ops` 已处理，或明确不需要。
- 本地索引已重建或可重建。
- 已进入提交前人工审核，并列出待提交文件。

默认不自动提交代码。只有用户明确回复“批准提交”或“确认提交”后，才提交聚焦 commit。

## 八、Git hooks

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

- 默认检查文档结构并重建索引。
- commit message 建议包含追踪编号；quick 可使用 `[quick]`。
- 需要强制代码变更伴随文档时，设置 `DEV_WORKFLOW_REQUIRE_DOCS=1`。

## 九、注意事项

- 不要为了“完整”补全所有历史。已有项目只从当前变更开始追踪。
- 小任务只写必要信息，不补无关文档。
- 旧文档归档后只作为历史参考，不作为当前实现依据。
- `ADR` 只记录重要决策，不要把每个小选择都写成 ADR。
- PRD / 改版类任务必须先做 REQ 追踪矩阵和 TDD 计划。
- 代码审查默认先自查，复杂或高风险任务再使用 subagent / 人工独立 review。
- 提交前必须人工审核，未经明确批准不自动 commit。
- Git hooks 默认不自动启用，避免影响临时项目。
- subagent 默认不使用，只在复杂、并行、高风险或需要独立 review 时使用。

## 十、与 Superpowers 配合

`dev-workflow` 可以和 Superpowers 一起用：

```text
Superpowers 负责方法
dev-workflow 负责追踪和门禁
```

建议搭配：

- 需求澄清：`brainstorming` → 写入 PRD / TASK。
- 计划制定：`writing-plans` → 写入 TASK。
- Bug 定位：`systematic-debugging` → 写入 BUG。
- 实现：`test-driven-development` → 写入最终摘要、主记录或 strict 的 ACC。
- 并行执行：`subagent-driven-development` → 结论写入主记录或 strict 文档链路。
- 完成验证：`verification-before-completion` → 写入最终摘要、主记录或 strict 的 ACC。
- 代码审查：`requesting-code-review` → 写入最终摘要、主记录或 strict 的 ACC。

dev-workflow 不替代 Superpowers，只负责建立追踪链路、沉淀关键结论、完成前检查文档，并在人工审核通过后提交。

## 十一、版本管理

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
