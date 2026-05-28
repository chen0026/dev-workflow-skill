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

skill_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_dir="$skill_root/assets/docs-template"

if [ ! -d "$template_dir" ]; then
  echo "dev-workflow: 找不到模板目录：$template_dir"
  exit 1
fi

mkdir -p "$target_dir"
cd "$target_dir"

if [ ! -f "AGENTS.md" ]; then
  cp "$skill_root/assets/agents-template.md" "AGENTS.md"
  echo "dev-workflow: 已创建 AGENTS.md"
elif ! grep -q "开发工作流强约束" "AGENTS.md"; then
  {
    printf '\n\n'
    cat "$skill_root/assets/agents-rule.md"
  } >> "AGENTS.md"
  echo "dev-workflow: 已追加 AGENTS.md 规则"
else
  echo "dev-workflow: AGENTS.md 已包含工作流规则"
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
  "$template_dir/README.md" \
  "$template_dir/workflow.md" \
  "$template_dir/index.md" \
  "$template_dir/prd" \
  "$template_dir/tasks" \
  "$template_dir/bugs" \
  "$template_dir/design" \
  "$template_dir/acceptance" \
  "$template_dir/ops" \
  "$template_dir/legacy" \
  docs/

mkdir -p docs/archive .githooks scripts
rsync -a --ignore-existing "$template_dir/.githooks/" .githooks/
rsync -a --ignore-existing "$template_dir/scripts/" scripts/

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
