#!/usr/bin/env bash
set -euo pipefail

apply="0"

for arg in "$@"; do
  case "$arg" in
    --apply)
      apply="1"
      ;;
    *)
      echo "usage: clean-project-scripts.sh [--apply]"
      exit 1
      ;;
  esac
done

if [ -f "SKILL.md" ] && [ -d "assets/docs-template" ]; then
  echo "dev-workflow: 当前目录看起来是 dev-workflow skill 源码目录，拒绝清理。请在业务项目根目录执行。"
  exit 1
fi

known_scripts="
scripts/check-dev-docs.sh
scripts/check-dev-workflow.sh
scripts/active-work.sh
scripts/commit-scope.sh
scripts/clean-project-scripts.sh
scripts/clean-templates.sh
scripts/dev-workflow-harness.sh
scripts/init-dev-workflow.sh
scripts/loop-work.sh
scripts/new-doc-id.sh
scripts/new-doc.sh
scripts/reindex-dev-docs.sh
scripts/search-dev-docs.sh
scripts/session-state.sh
"

found=""
while IFS= read -r file; do
  [ -n "$file" ] || continue
  if [ -f "$file" ]; then
    found="${found}${file}
"
  fi
done <<EOF
$known_scripts
EOF

if [ -z "$found" ]; then
  echo "dev-workflow: 未发现项目内 dev-workflow 脚本副本"
  exit 0
fi

if [ "$apply" != "1" ]; then
  echo "dev-workflow: 将清理以下项目内 dev-workflow 脚本副本（预览，不会删除）："
  printf '%s' "$found"
  echo
  echo "dev-workflow: 确认后执行：clean-project-scripts.sh --apply"
  exit 0
fi

printf '%s' "$found" | while IFS= read -r file; do
  [ -n "$file" ] || continue
  rm -f "$file"
  echo "dev-workflow: 已删除 $file"
done

if [ -d "scripts" ] && [ -z "$(find scripts -mindepth 1 -print -quit)" ]; then
  rmdir scripts
  echo "dev-workflow: scripts/ 已为空，已删除目录"
fi

echo "dev-workflow: 项目脚本副本清理完成"
