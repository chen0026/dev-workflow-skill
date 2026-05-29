#!/usr/bin/env bash
set -euo pipefail

type="${1:?usage: scripts/new-doc.sh TYPE short-title}"
title="${2:?usage: scripts/new-doc.sh TYPE short-title}"

case "$type" in
  PRD)
    dir="docs/prd"
    template_rel="prd/TEMPLATE.md"
    ;;
  TASK)
    dir="docs/tasks"
    template_rel="tasks/TEMPLATE.md"
    ;;
  REQ)
    dir="docs/requirements"
    template_rel="requirements/TEMPLATE.md"
    ;;
  BUG)
    dir="docs/bugs"
    template_rel="bugs/TEMPLATE.md"
    ;;
  ADR)
    dir="docs/design/decisions"
    template_rel="design/decisions/TEMPLATE.md"
    ;;
  ACC)
    dir="docs/acceptance"
    template_rel="acceptance/TEMPLATE.md"
    ;;
  OPS)
    dir="docs/ops"
    template_rel="ops/TEMPLATE.md"
    ;;
  LEGACY)
    dir="docs/legacy"
    template_rel="legacy/TEMPLATE.md"
    ;;
  *)
    echo "dev-workflow: TYPE 必须是 PRD/REQ/TASK/BUG/ADR/ACC/OPS/LEGACY"
    exit 1
    ;;
esac

local_template="$dir/TEMPLATE.md"
skill_template="${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow/assets/docs-template/$template_rel"

if [ -f "$local_template" ]; then
  template="$local_template"
elif [ -f "$skill_template" ]; then
  template="$skill_template"
else
  echo "dev-workflow: 找不到模板：$local_template 或 $skill_template"
  echo "dev-workflow: 请确认已安装 dev-workflow，或使用 init --with-templates 初始化项目模板。"
  exit 1
fi

id="$(scripts/new-doc-id.sh "$type" "$title")"
target="$dir/$id.md"

mkdir -p "$dir"
cp "$template" "$target"
echo "$target"
