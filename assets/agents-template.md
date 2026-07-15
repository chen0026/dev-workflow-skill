# AGENTS.md

## Dev Workflow Lite

普通 Bug、功能、重构和维护任务默认直接调查、实现、测试和审查；不强制创建文档、运行 harness、Loop 或索引脚本。

### 按需升级

- 跨会话、换 agent、多人并行或明确交接时，只使用一个 `docs/active/ACTIVE-*.md`记录目标、进度、相关文件、下一步和验证结果。
- PRD 改版、多模块、接口契约、数据迁移、权限、支付、部署或其他高风险变更，只建立一个 `DEV`，编码前确认需求基线和验收矩阵。
- 只在需求不清、验证失败或复杂任务需要切片时使用 harness 或 Loop。

### 开发与验收

- 修改前定向确认真实调用链、影响范围、可复用能力和回归测试，不为普通任务撰写长文档。
- 最终验收使用真实后端、真实接口、真实环境或人工实测证据；mock、fixture、stub 和 Playwright route mock 只能作为辅助测试。
- 关键业务代码只在不注释难以理解时补简短中文注释，不逐行翻译代码。
- 最终回复只列代码变更、验证结果、待提交文件、风险或未完成项。

### 提交

- 默认不自动 commit；只有用户明确批准后才提交。
- 请求提交时才用已安装 skill 的 `commit-scope.sh prepare TASK_KEY`生成任务独立清单，批准后用 `commit-scope.sh commit TASK_KEY ...`精确提交。

### Dev Workflow One Approval

- 提交前一次性展示文件范围、完整 commit message 和验证结果；使用 DEV 时再展示 DEV 变化，只询问一次。
- 用户回复“提交代码 / 确认提交 / 批准提交”后立即暂存并提交，不得为暂存、hooks 或 commit 再次确认。
- 只有确认后审核包内容发生变化时，才展示变化并重新确认一次。

### Dev Workflow Git Record

- 普通修改不创建 CHG、REQ、TASK、BUG 或 ACC，结构化 Git commit 记录原因、变更、验证和影响。
- 复杂任务只维护一个 `docs/work/YYYY/MM/DEV-*.md`，贯穿需求、计划、问题、进度、验收和关联 commits。
- DEV 和 commit message 不得包含密钥、token、客户隐私或生产数据。
- `.dev-workflow/` 是本地状态，必须忽略且不提交。

### Dev Workflow Isolated Commit

- 共享工作区只在 manifest 中列本任务文件，通过 `commit-scope.sh commit TASK_KEY ...`使用 `git commit --only`，保留其他任务暂存状态。
- 不得为了当前任务取消其他任务的暂存状态；不同任务修改同一文件时停止并人工确认。

### Dev Workflow Thread Files

- 每个线程使用稳定 TASK_KEY；首次修改文件前由 Agent 后台执行 `commit-scope.sh track TASK_KEY -- FILE...`，后续发现文件时增量记录，用户无须操作。
- track 只记录本线程文件，不分类整个工作区；文件已被其他线程记录时在编码前停止。正常情况仍由本线程直接提交。
- 只有 commit 成功、HEAD 变化、提交文件与本线程记录一致且这些文件无残留时，才能报告提交成功。

追查时先用 `git log --follow -- FILE`、`git blame` 和 `git show COMMIT` 查真实 diff；复杂任务再读取关联 DEV。
