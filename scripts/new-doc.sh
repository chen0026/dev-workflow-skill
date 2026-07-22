#!/usr/bin/env bash
set -euo pipefail

type="${1:?usage: new-doc.sh DEV|ADR|OPS short-title}"
title="${2:?usage: new-doc.sh DEV|ADR|OPS short-title}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_root="$(cd "$script_dir/.." && pwd)"

case "$type" in
  DEV)
    dir="docs/work/$(date +%Y)/$(date +%m)"
    template_rel="work/TEMPLATE.md"
    ;;
  ADR)
    dir="docs/design/decisions"
    template_rel="design/decisions/TEMPLATE.md"
    ;;
  OPS)
    dir="docs/ops"
    template_rel="ops/TEMPLATE.md"
    ;;
  *)
    echo "dev-workflow: TYPE 必须是 DEV/ADR/OPS"
    exit 1
    ;;
esac

local_template="$dir/TEMPLATE.md"
skill_template="$skill_root/assets/docs-template/$template_rel"

if [ -f "$local_template" ]; then
  template="$local_template"
elif [ -f "$skill_template" ]; then
  template="$skill_template"
else
  echo "dev-workflow: 找不到模板：$local_template 或 $skill_template"
  exit 1
fi

id="$("$script_dir/new-doc-id.sh" "$type" "$title")"
target="$dir/$id.md"
mkdir -p "$dir"
cp "$template" "$target"

created_at="$(date +%Y-%m-%dT%H:%M:%S%z)"
tmp="$(mktemp)"
awk -v id="$id" -v title="$title" -v created_at="$created_at" '
  BEGIN { heading = 0 }
  /^id:/ { print "id: " id; next }
  /^created_at:/ { print "created_at: " created_at; next }
  /^updated_at:/ { print "updated_at: " created_at; next }
  /^# / && heading == 0 { print "# " title; heading = 1; next }
  { print }
' "$target" > "$tmp"
mv "$tmp" "$target"

echo "$target"
