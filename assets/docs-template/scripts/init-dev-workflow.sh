#!/usr/bin/env bash
set -euo pipefail

target_dir="$(pwd)"
enable_hooks="0"

for arg in "$@"; do
  case "$arg" in
    --enable-hooks)
      enable_hooks="1"
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
3. `docs/index.md`
4. 当前任务关联的 `PRD / TASK / BUG / ADR / ACC`
5. `docs/design/` 和 `docs/ops/`
6. `docs/legacy/`
7. `docs/archive/`
8. 代码和测试

没有完成文档同步和人工审核，不得声明任务最终完成；未经用户批准，不得提交代码。
EOF
  echo "dev-workflow: 已创建 AGENTS.md"
elif ! grep -q "开发工作流强约束" "AGENTS.md"; then
  cat >> "AGENTS.md" <<'EOF'


## 开发工作流强约束

所有新功能、Bug 修复、重构、维护任务必须遵守 `docs/workflow.md`。
没有完成文档同步和人工审核，不得声明任务最终完成；未经用户批准，不得提交代码。
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
  "$docs_source/prd" \
  "$docs_source/requirements" \
  "$docs_source/tasks" \
  "$docs_source/bugs" \
  "$docs_source/design" \
  "$docs_source/acceptance" \
  "$docs_source/ops" \
  "$docs_source/legacy" \
  docs/

mkdir -p docs/archive .githooks scripts
[ -d "$hooks_source" ] && rsync -a --ignore-existing "$hooks_source/" .githooks/
[ -d "$scripts_source" ] && rsync -a --ignore-existing "$scripts_source/" scripts/

chmod +x .githooks/pre-commit .githooks/commit-msg scripts/check-dev-workflow.sh 2>/dev/null || true
chmod +x scripts/init-dev-workflow.sh scripts/check-dev-docs.sh scripts/new-doc-id.sh scripts/new-doc.sh 2>/dev/null || true

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
