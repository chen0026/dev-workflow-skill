---
name: dev-workflow
description: "Native agent development workflow for /dev-workflow commands, PRD, feature, bug, refactor, review, verification, handoff, traceable docs, and human-approved Git commits."
---

# Dev Workflow Native

把 Codex、Claude 等现代 Agent 当作执行主体。本 Skill 只提供完成标准和必要门禁，不重复实现规划器、循环器或线程调度器。

## Default Path

普通 Bug、功能、重构和维护任务：

1. 从用户目标、相关代码和 `AGENTS.md`提取 Goal、Context、Constraints、Done when。
2. 定向检查真实入口、调用链、影响范围、现有复用能力和回归测试。
3. 直接实现；按风险补测试并执行真实验证。
4. 对照需求审查最终 diff，修复遗漏后报告代码变更、验证结果、风险和待提交文件。

默认不创建任务文档，不运行 harness、Loop、索引或文件认领脚本。

## Native Escalation

- 需求模糊、改动复杂或高风险时，使用宿主的原生 Plan mode；计划确认后再实现。
- 可独立的检索、日志、测试和审查可交给 subagent；共享工作区默认由主 Agent 统一写代码。
- 跨会话、换 Agent 或需要长期追溯时，只维护一个 `DEV`文档；结构见 `references/flow.md`。
- 验证失败时由 Agent 自主调查、修改和重试，不要求显式 Loop 命令。

## Hard Gates

- mock、fixture、stub 和 route mock 只能辅助测试，不能替代可用的真实链路验收。
- 完成前必须核对“需求/验收项 -> 实现 -> 测试或真实证据”，有缺口就明确未完成。
- 不在开发前认领或锁定文件。发现同文件并行修改时提示风险；无法可靠拆分时联合提交或使用宿主原生隔离。
- 默认不自动 commit。提交前一次性展示待提交文件、完整 commit message 和验证结果，只等待一次人工批准。
- 批准后立即提交，不为 stage、hooks 或 commit 重复确认；提交成功必须以命令成功、HEAD 变化和工作区核验为准。
- 普通任务用结构化 Git commit 留痕；只有复杂或跨会话任务才写 DEV。
- DEV 和 commit message 不得包含密钥、token、客户隐私、生产数据或内网凭据。

## Commands

- `/dev-workflow init [--hooks]`：轻量接入或迁移旧项目。
- `/dev-workflow check|doctor|version`：按需检查，不在每次任务前运行。
- `/dev-workflow history <关键词|文件>`：优先查询 Git history，必要时再读关联 DEV。

模式选择、上下文预算和 Agent 协作见 `references/flow.md`；验收、文档、审查与提交见 `references/details.md`。
