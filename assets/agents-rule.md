## Dev Workflow Lite（覆盖旧版规则）

本节覆盖同一文件中旧的 Harness-first、Loop Guard、Implementation Map Guard 和“每个任务都需要 ACTIVE”规则。普通 Bug、功能、重构和维护任务默认直接调查、实现、测试和审查，不强制创建文档或运行 harness、Loop、索引脚本。修改前定向确认真实调用链、影响范围、可复用能力和回归测试。

- 跨会话、换 agent、多人并行或明确交接时，只使用一个 `docs/active/ACTIVE-*.md`。
- PRD 改版、多模块、接口契约、数据迁移、权限、支付、部署或其他高风险变更，只建立一个 `DEV`，编码前确认需求基线和验收矩阵。
- 最终验收必须有真实后端、真实接口、真实环境或人工实测证据；mock 只能辅助。
- 默认不自动 commit；请求提交时才生成精确提交清单，得到用户批准后才 stage 和 commit。

### Dev Workflow One Approval

- 提交前一次性展示文件范围、完整 commit message 和验证结果；使用 DEV 时再展示 DEV 变化，只询问一次。
- 用户回复“提交代码 / 确认提交 / 批准提交”后立即暂存并提交，不得为暂存、hooks 或 commit 再次确认。
- 只有确认后审核包内容发生变化时，才展示变化并重新确认一次。

### Dev Workflow Git Record

- 本节覆盖旧的 Dev Workflow CHG Record：普通修改不再创建 CHG、REQ、TASK、BUG 或 ACC，结构化 Git commit 是修改历史的唯一事实记录。
- 复杂任务只维护一个 `docs/work/YYYY/MM/DEV-*.md`，贯穿需求、计划、问题、进度、验收和关联 commits。
- DEV 和 commit message 不得包含密钥、token、客户隐私或生产数据。
- `.dev-workflow/` 只保存本地状态，必须忽略且不提交。

### Dev Workflow Isolated Commit

- 共享工作区为每个任务使用独立 `.dev-workflow/commits/TASK_KEY.txt`；批准后通过 `commit-scope.sh commit TASK_KEY ...`仅提交本任务文件，保留其他任务暂存状态。
- 不得为了当前任务取消其他任务的暂存状态。同一文件被多个任务认领时停止并人工确认。

### Dev Workflow Thread Files

- 每个线程使用稳定 TASK_KEY；首次修改文件前由 Agent 后台执行 `commit-scope.sh track TASK_KEY -- FILE...`，后续发现文件时增量记录，用户无须操作。
- track 只记录本线程文件，不分类整个工作区；文件已被其他线程记录时在编码前停止。正常情况仍由本线程直接提交。
- 只有 commit 成功、HEAD 变化、提交文件与本线程记录一致且这些文件无残留时，才能报告提交成功。
