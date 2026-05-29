#!/usr/bin/env bash
set -euo pipefail

type="${1:?usage: scripts/new-doc.sh TYPE short-title}"
title="${2:?usage: scripts/new-doc.sh TYPE short-title}"

case "$type" in
  PRD)
    dir="docs/prd"
    template="$dir/TEMPLATE.md"
    ;;
  TASK)
    dir="docs/tasks"
    template="$dir/TEMPLATE.md"
    ;;
  REQ)
    dir="docs/requirements"
    template="$dir/TEMPLATE.md"
    ;;
  BUG)
    dir="docs/bugs"
    template="$dir/TEMPLATE.md"
    ;;
  ADR)
    dir="docs/design/decisions"
    template="$dir/TEMPLATE.md"
    ;;
  ACC)
    dir="docs/acceptance"
    template="$dir/TEMPLATE.md"
    ;;
  OPS)
    dir="docs/ops"
    template="$dir/TEMPLATE.md"
    ;;
  LEGACY)
    dir="docs/legacy"
    template="$dir/TEMPLATE.md"
    ;;
  *)
    echo "dev-workflow: TYPE 必须是 PRD/REQ/TASK/BUG/ADR/ACC/OPS/LEGACY"
    exit 1
    ;;
esac

[ -f "$template" ] || {
  echo "dev-workflow: 找不到模板：$template"
  exit 1
}

id="$(scripts/new-doc-id.sh "$type" "$title")"
target="$dir/$id.md"

cp "$template" "$target"
echo "$target"
