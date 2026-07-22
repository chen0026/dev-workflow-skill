# AGENTS.md

记录本项目特有的目录、命令、工程规范、限制和完成标准。保持简短准确；不要复制通用 Agent 能力或临时任务计划。

## Project Commands

- Build: 按项目补充
- Test: 按项目补充
- Lint: 按项目补充

## Project Constraints

- 按项目补充架构、兼容性、安全和禁止事项。

<!-- dev-workflow:start -->
## Dev Workflow Native

- 普通 Bug、功能、重构和维护默认直接调查、实现、测试和审查，不创建过程文档。
- 需求模糊、复杂或高风险时使用原生 Plan mode；跨会话或需要长期追溯时只维护一个 DEV。
- subagent 优先用于检索、日志、测试和审查；共享工作区默认由主 Agent 统一写代码。
- 不在开发前认领或锁定文件。同文件并行修改要提示风险，无法可靠拆分时联合提交或使用原生隔离。
- mock 和 route mock 只能辅助测试，不能替代可用的真实链路验收。
- 完成前核对需求、实现和验证证据，并审查最终 diff。
- 默认不自动 commit；提交前一次性展示文件范围、完整 commit message 和验证结果，只等待一次人工批准。
- 普通任务用结构化 Git commit 留痕；复杂任务使用一个 `docs/work/YYYY/MM/DEV-*.md`。
<!-- dev-workflow:end -->
