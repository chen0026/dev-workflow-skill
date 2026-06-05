# Superpowers Integration

如果当前环境有 Superpowers，可以按阶段配合使用：

- 需求澄清：`brainstorming`，结论写入 PRD / REQ / TASK。
- 计划制定：`writing-plans`，任务拆解写入 TASK。
- Bug 定位：`systematic-debugging`，复现、路径、根因写入 BUG。
- 实现：`test-driven-development`，验证方式写入最终摘要、主记录或 strict 的 ACC。
- 并行执行：`subagent-driven-development`，各 subagent 结论写入主记录或 strict 文档链路。
- 完成验证：`verification-before-completion`，验证结果写入最终摘要、主记录或 strict 的 ACC。
- 代码审查：`requesting-code-review`，审查结论写入最终摘要、主记录或 strict 的 ACC。

dev-workflow 不替代 Superpowers，只负责建立追踪链路、沉淀关键结论、完成前检查文档，并在人工审核通过后提交。

## Subagent 使用规则

默认不使用 subagent。满足以下任一条件时才使用：

- 任务涉及多个独立模块。
- Bug 根因不明确。
- 需要并行调查代码路径、测试、文档或影响范围。
- 改动影响范围较大。
- 完成前需要独立 review 或 QA 检查。

subagent 输出按流程级别沉淀：

- quick：最终回复列出关键结论。
- standard：结论写入 TASK 或 BUG 主记录。
- strict：结论写入 PRD / REQ / TASK / BUG / ACC / ADR 中的对应位置。
