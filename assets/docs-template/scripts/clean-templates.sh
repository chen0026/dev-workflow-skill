#!/usr/bin/env bash
set -euo pipefail

apply="0"

for arg in "$@"; do
  case "$arg" in
    --apply)
      apply="1"
      ;;
    *)
      echo "usage: scripts/clean-templates.sh [--apply]"
      exit 1
      ;;
  esac
done

[ -d "docs" ] || {
  echo "dev-workflow: 缺少 docs/ 目录"
  exit 1
}

templates="$(find docs -type f -name TEMPLATE.md | sort)"

if [ -z "$templates" ]; then
  echo "dev-workflow: 未发现 docs/**/TEMPLATE.md"
  exit 0
fi

if [ "$apply" != "1" ]; then
  echo "dev-workflow: 将清理以下模板文件（预览，不会删除）："
  printf '%s\n' "$templates"
  echo
  echo "dev-workflow: 确认后执行 scripts/clean-templates.sh --apply"
  exit 0
fi

printf '%s\n' "$templates" | while IFS= read -r file; do
  rm -f "$file"
  echo "dev-workflow: 已删除 $file"
done

echo "dev-workflow: 模板清理完成"
