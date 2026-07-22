#!/usr/bin/env bash
set -euo pipefail

mode="${1:-staged}"

fail() {
  echo "dev-workflow: $1"
  exit 1
}

validate_dev() {
  dev="$1"
  [ -f "$dev" ] || fail "DEV 文件不存在：$dev"
  grep -Eq '^id: DEV-[0-9]{8}-[0-9]{6}-[a-z0-9]{4}-.+' "$dev" || fail "$dev 缺少有效 id"
  for section in '需求基线' '实现计划' '问题与决策' '验收矩阵' '执行进度' 'Git 记录'; do
    grep -q "^## ${section}$" "$dev" || fail "$dev 缺少${section}"
  done
}

if [ "$mode" = "--staged" ] || [ "$mode" = "staged" ]; then
  while IFS= read -r dev; do
    [ -n "$dev" ] || continue
    validate_dev "$dev"
  done < <(git diff --cached --name-only --diff-filter=AM | grep -E '^docs/work/[0-9]{4}/[0-9]{2}/DEV-.*\.md$' || true)
elif [ "$mode" = "--all" ] || [ "$mode" = "all" ]; then
  [ -d docs/work ] || {
    echo "dev-workflow: 没有 docs/work，文档检查通过"
    exit 0
  }
  while IFS= read -r dev; do
    validate_dev "$dev"
  done < <(find docs/work -type f -name 'DEV-*.md' | LC_ALL=C sort)
else
  fail "模式必须是 staged 或 all"
fi

echo "dev-workflow: 文档检查通过"
