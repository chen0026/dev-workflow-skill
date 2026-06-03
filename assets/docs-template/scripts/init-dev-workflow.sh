#!/usr/bin/env bash
set -euo pipefail

target_dir="$(pwd)"
enable_hooks="0"
with_templates="0"

for arg in "$@"; do
  case "$arg" in
    --enable-hooks)
      enable_hooks="1"
      ;;
    --with-templates)
      with_templates="1"
      ;;
    *)
      target_dir="$arg"
      ;;
  esac
done

template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$template_root/workflow.md" ]; then
  docs_source="$template_root"
else
  docs_source="$template_root/docs"
fi

hooks_source="$template_root/.githooks"
scripts_source="$template_root/scripts"

if [ ! -f "$docs_source/workflow.md" ]; then
  echo "dev-workflow: 找不到 docs 模板"
  exit 1
fi

mkdir -p "$target_dir"
cd "$target_dir"

if [ ! -f "AGENTS.md" ]; then
  cat > "AGENTS.md" <<'EOF'
# AGENTS.md

## 开发工作流强约束

所有新功能、Bug 修复、重构、维护任务必须遵守 `docs/workflow.md`。

## 文档查找优先级

1. `AGENTS.md`
2. `docs/workflow.md`
3. `scripts/search-dev-docs.sh` 的候选结果，或 `.dev-workflow/index/docs.jsonl`
4. 当前任务关联的 `PRD / REQ / TASK / BUG / ADR / ACC`
5. `docs/design/` 和 `docs/ops/`
6. `docs/legacy/`
7. `docs/archive/`
8. 代码和测试

没有完成文档同步和人工审核，不得声明任务最终完成；未经用户批准，不得提交代码。

## 文档读取预算

默认只读取 `AGENTS.md`、`docs/workflow.md`、`scripts/search-dev-docs.sh` 的候选结果、用户当前提供的 PRD / 需求 / Bug 描述、与当前任务直接相关的文档。

默认禁止全量读取 `docs/archive/**`、全部 PRD、全部 REQ、全部 TASK、全部 BUG、全部 ACC、全部 ADR。必须先根据本地索引、当前任务关键词、模块名、功能名、编号筛选候选文档。

`.dev-workflow/index/` 是可重建的本地机器索引，默认不提交。`docs/index.md` 只作为人类入口说明，不再作为每次任务必须手工更新的共享索引。
EOF
  echo "dev-workflow: 已创建 AGENTS.md"
elif ! grep -q "开发工作流强约束" "AGENTS.md"; then
  cat >> "AGENTS.md" <<'EOF'


## 开发工作流强约束

所有新功能、Bug 修复、重构、维护任务必须遵守 `docs/workflow.md`。
没有完成文档同步和人工审核，不得声明任务最终完成；未经用户批准，不得提交代码。

## 文档读取预算

默认只读取 `AGENTS.md`、`docs/workflow.md`、`scripts/search-dev-docs.sh` 的候选结果、用户当前提供的 PRD / 需求 / Bug 描述、与当前任务直接相关的文档。默认禁止全量读取历史文档。

`.dev-workflow/index/` 是可重建的本地机器索引，默认不提交。`docs/index.md` 只作为人类入口说明，不再作为每次任务必须手工更新的共享索引。
EOF
  echo "dev-workflow: 已追加 AGENTS.md 规则"
fi

if [ -d "docs" ] && { [ ! -f "docs/workflow.md" ] || [ ! -f "docs/index.md" ]; }; then
  archive_dir="docs/archive/legacy-docs-$(date +%Y%m%d-%H%M%S)"
  movable="$(find docs -mindepth 1 -maxdepth 1 ! -name archive -print)"

  if [ -n "$movable" ]; then
    mkdir -p "$archive_dir"
    while IFS= read -r item; do
      mv "$item" "$archive_dir/"
    done <<EOF
$movable
EOF
    echo "dev-workflow: 已归档旧 docs 到 $archive_dir"
  fi
fi

mkdir -p docs
rsync -a --ignore-existing \
  "$docs_source/README.md" \
  "$docs_source/workflow.md" \
  "$docs_source/index.md" \
  docs/

mkdir -p \
  docs/prd \
  docs/requirements \
  docs/tasks \
  docs/bugs \
  docs/design/decisions \
  docs/acceptance \
  docs/ops \
  docs/legacy \
  docs/archive \
  .dev-workflow/index \
  .dev-workflow/session \
  .githooks \
  scripts

if [ "$with_templates" = "1" ]; then
  rsync -a --ignore-existing \
    "$docs_source/prd" \
    "$docs_source/requirements" \
    "$docs_source/tasks" \
    "$docs_source/bugs" \
    "$docs_source/design" \
    "$docs_source/acceptance" \
    "$docs_source/ops" \
    "$docs_source/legacy" \
    docs/
  echo "dev-workflow: 已复制模板到项目 docs/"
fi

[ -d "$hooks_source" ] && rsync -a --ignore-existing "$hooks_source/" .githooks/
[ -d "$scripts_source" ] && rsync -a --ignore-existing "$scripts_source/" scripts/

chmod +x .githooks/pre-commit .githooks/commit-msg scripts/check-dev-workflow.sh 2>/dev/null || true
chmod +x scripts/init-dev-workflow.sh scripts/check-dev-docs.sh scripts/new-doc-id.sh scripts/new-doc.sh scripts/clean-templates.sh scripts/session-state.sh scripts/reindex-dev-docs.sh scripts/search-dev-docs.sh 2>/dev/null || true

touch .gitignore
if ! grep -qxF ".dev-workflow/index/" .gitignore; then
  printf '\n.dev-workflow/index/\n' >> .gitignore
  echo "dev-workflow: 已把 .dev-workflow/index/ 加入 .gitignore"
fi

if [ "$enable_hooks" = "1" ]; then
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git config core.hooksPath .githooks
    echo "dev-workflow: 已启用 Git hooks"
  else
    echo "dev-workflow: 当前目录不是 Git 仓库，未启用 Git hooks"
  fi
else
  echo "dev-workflow: Git hooks 未自动启用。需要时执行：git config core.hooksPath .githooks"
fi

echo "dev-workflow: 初始化完成"
