## Dev Workflow Lite（覆盖旧版规则）

本节覆盖同一文件中旧的 Harness-first、Loop Guard、Implementation Map Guard 和“每个任务都需要 ACTIVE”规则。普通 Bug、功能、重构和维护任务默认直接调查、实现、测试和审查，不强制创建文档或运行 harness、Loop、索引脚本。修改前定向确认真实调用链、影响范围、可复用能力和回归测试。

- 跨会话、换 agent、多人并行或明确交接时，只使用一个 `docs/active/ACTIVE-*.md`。
- PRD 改版、多模块、接口契约、数据迁移、权限、支付、部署或其他高风险变更，编码前建立并人工确认 `REQ` 和验收矩阵。
- 最终验收必须有真实后端、真实接口、真实环境或人工实测证据；mock 只能辅助。
- 默认不自动 commit；请求提交时才生成精确提交清单，得到用户批准后才 stage 和 commit。

### Dev Workflow CHG Record

- 普通 Bug / 功能不新建 REQ、TASK、BUG 或 ACC 留痕。正式提交时恰好新增一个精简 `docs/changes/YYYY/MM/CHG-*.md`，并根据实际 diff 生成 `fix/feat(scope): 摘要`，正文记录原因、变更、验证和影响；用户同时确认文件范围、CHG 和 commit message 后才 commit。
- CHG 和 commit message 不得包含密钥、token、客户隐私或生产数据。
- `.dev-workflow/` 只保存本地状态，必须忽略且不提交。
