# ACTIVE-YYYYMMDD-HHMMSS-XXXX-short-title

> 进行中任务交接文件。一个任务只保留一个 ACTIVE；完成后折叠到 `docs/history/<module>.md` 并删除本文件。

## 基本信息

- 状态：intake / pre_code_doc / coding / testing / blocked / review
- ACTIVE 文件：
- 任务指纹：
- 模块：
- 来源：
- 分支：
- 创建时间：
- 最后更新：
- 编码前确认：未确认
- 测试用例确认：未确认

## 当前目标

- 目标：
- 不做：
- 范围：

## 当前状态

- 已完成：
- 未完成：
- 下一步：
- 阻塞：

## Loop 记录

- 最大轮次：3
- 规则：每轮必须 step -> verify -> decide；continue / retry / rescope 前必须有真实验证证据。

## 测试用例清单

| 关联 | 场景 | 前置状态 | 操作 / 触发 | 期望结果 | 类型 | 真实验证路径 | mock 限制 | RED 失败记录 |
|------|------|----------|-------------|----------|------|--------------|-----------|--------------|
| ACTIVE |  |  |  |  |  |  | 仅辅助，不作最终验收 |  |

## 修改文件

- 

## 验证与审查

- 最终验收来源：
- 最终验收证据：
- 辅助模拟记录：
- 注释审查：
- 代码审查：

## 折叠到 history

- history 文件：
- 8 行以内摘要：
- ACTIVE 清理：未清理

> 人工审核通过后，可用 `active-work.sh finish ACTIVE_FILE module-name < summary.md` 折叠并清理。
