# 项目开发文档

本项目使用 Dev Workflow Lite。普通 Bug、功能、重构和维护默认直接开发，不为每个任务创建文档。

## 何时写文档

- 跨会话、换 agent、多人并行或需要交接：只写一个 `active/ACTIVE-*.md`。
- PRD 改版、多模块、接口契约、数据迁移、权限、支付、部署等高风险变更：编码前写并确认 `requirements/REQ-*.md`。
- 需要长期追溯的设计决策、故障复盘或运维流程：按需写 ADR、BUG 或 OPS。

TASK、BUG、ACC 不是配套文档，没有独立长期价值就不创建。

## 核心规则

- 修改前定向确认真实调用链、影响范围、可复用能力和回归测试。
- 最终验收使用真实后端、真实接口、真实环境或人工实测证据；mock 只能辅助。
- 默认不自动 commit，人工批准后才提交。
- 普通 Bug / 功能不新建 REQ、TASK、BUG 或 ACC 留痕；正式提交时只新增一个精简 CHG，并用结构化 Git message 记录原因、变更、验证和影响。
- 需要历史时才运行 `search-dev-docs.sh`，不在每个任务前重建索引。
- `.dev-workflow/` 和 `docs/index.md` 是可重建本地状态，不提交。

详细规则见 [`workflow.md`](workflow.md)。
