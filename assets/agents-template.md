# AGENTS.md

## Dev Workflow Lite

普通 Bug、功能、重构和维护任务默认直接调查、实现、测试和审查；不强制创建文档、运行 harness、Loop 或索引脚本。

### 按需升级

- 跨会话、换 agent、多人并行或明确交接时，只使用一个 `docs/active/ACTIVE-*.md`记录目标、进度、相关文件、下一步和验证结果。
- PRD 改版、多模块、接口契约、数据迁移、权限、支付、部署或其他高风险变更，编码前建立并人工确认 `REQ` 和验收矩阵。
- 只在需求不清、验证失败或复杂任务需要切片时使用 harness 或 Loop。

### 开发与验收

- 修改前定向确认真实调用链、影响范围、可复用能力和回归测试，不为普通任务撰写长文档。
- 最终验收使用真实后端、真实接口、真实环境或人工实测证据；mock、fixture、stub 和 Playwright route mock 只能作为辅助测试。
- 关键业务代码只在不注释难以理解时补简短中文注释，不逐行翻译代码。
- 最终回复只列代码变更、验证结果、待提交文件、风险或未完成项。

### 提交

- 默认不自动 commit；只有用户明确批准后才提交。
- 请求提交时才用已安装 skill 的 `commit-scope.sh prepare`生成临时清单，批准后精确 stage/check。

### Dev Workflow CHG Record

- 普通 Bug / 功能不新建 REQ、TASK、BUG 或 ACC 留痕。正式提交时恰好新增一个 `docs/changes/YYYY/MM/CHG-*.md`，只记录元数据、原因、变更、验证和影响。
- 同时根据实际 diff 生成结构化 Git 记录：`fix/feat(scope): 摘要`，正文包含原因、变更、验证和影响。
- CHG 和 commit message 不得包含密钥、token、客户隐私或生产数据。
- 审核时同时展示待提交文件、CHG 和 commit message；用户确认三者后才 commit。
- 并行任务优先独立 Git worktree；共享工作区时使用 `--other` 分类其他任务文件。
- `.dev-workflow/` 是本地状态，必须忽略且不提交。

追查时先用 `rg` 定向搜索 `docs/changes/`，再用 `git log --follow -- FILE`、`git blame` 和 `git show COMMIT` 查真实 diff。不在每个任务前全量读取 CHG。
