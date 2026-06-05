# Context Budget

目标：避免每次任务全量读取历史文档，减少 token 和旧文档干扰。

## 默认读取

默认只读取：

- `AGENTS.md`
- `docs/workflow.md`
- `scripts/search-dev-docs.sh` 的候选结果，或 `.dev-workflow/index/docs.jsonl` 中的少量匹配行
- 用户当前提供的 PRD / 需求 / Bug 描述
- 与当前任务直接相关的文档

## 禁止默认全量读取

不要默认读取：

- `docs/archive/**`
- 全部 PRD
- 全部 REQ
- 全部 TASK
- 全部 BUG
- 全部 ACC
- 全部 ADR

## 查找顺序

1. 先运行 `scripts/reindex-dev-docs.sh` 重建本地索引；如果索引已存在且刚重建过，可直接使用。
2. 用 `scripts/search-dev-docs.sh 关键词` 按任务关键词、模块名、功能名、编号筛选候选文档。
3. 只打开候选文档中最相关的 1-5 个。
4. 如果候选过多，先列出候选并说明选择依据。
5. 只有搜索结果不足、任务涉及历史行为、或当前代码与文档冲突时，才搜索更多 docs。

## 本地索引

`.dev-workflow/index/docs.jsonl` 是可重建的机器索引，默认不提交。它用于快速定位文档，避免读取全部历史文档。

`docs/index.md` 只作为人类入口说明，不再作为每次任务必须手工更新的共享索引，避免多分支合并冲突。

## archive 规则

`docs/archive/` 默认不读。只有满足以下条件才读：

- 当前任务明确依赖归档历史。
- `legacy` 或当前文档引用了 archive。
- 用户要求追溯旧历史。

如果当前代码与 archive 冲突，以当前代码和当前链路文档为准。

## 文档写入策略

小任务不要一开始就写很多文档：

- quick：默认不写正式文档，只在最终回复摘要；必要时一个 TASK。
- standard：完成前回填一个 TASK 或 BUG 主记录。
- strict：PRD / 改版必须先写 REQ，确认后再编码。
