# 文档索引

此文件是人类入口说明，不再要求每次任务手工更新。

机器索引由以下命令生成到 `.dev-workflow/index/docs.jsonl`：

```bash
scripts/reindex-dev-docs.sh
```

检索历史文档：

```bash
scripts/search-dev-docs.sh login
scripts/search-dev-docs.sh TASK-20260528
```

如确实需要生成一个人类可读索引，可执行：

```bash
scripts/reindex-dev-docs.sh --write-md
```

注意：`--write-md` 会覆盖本文件。日常开发不要求提交生成后的 `docs/index.md`，避免多分支合并冲突。

## 编号规则

统一使用：

```text
TYPE-YYYYMMDD-HHMMSS-XXXX-short-title.md
```

- `YYYYMMDD-HHMMSS` 使用创建文档时的本地时间。
- `XXXX` 使用 4 位小写随机码，避免多电脑、多分支同秒创建时冲突。
- 合并后按文件名即可看出大致创建顺序。

示例：

| 类型 | 示例编号 |
|------|----------|
| PRD | PRD-20260528-153000-a1b2 |
| REQ | REQ-20260529-101500-a1b2 |
| TASK | TASK-20260528-153500-b2c3 |
| BUG | BUG-20260528-154000-c3d4 |
| ADR | ADR-20260528-154500-d4e5 |
| ACC | ACC-20260528-155000-e5f6 |
| OPS | OPS-20260528-155500-f6a7 |
| LEGACY | LEGACY-20260528-160000-a7b8 |

## 多分支规则

- 日常任务新增或更新各自的 `PRD / REQ / TASK / BUG / ADR / ACC` 文件。
- `.dev-workflow/index/docs.jsonl` 是可重建缓存，默认不提交。
- `docs/index.md` 不作为任务完成门禁，不要求每次提交都修改。
