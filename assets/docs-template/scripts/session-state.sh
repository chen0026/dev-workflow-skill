#!/usr/bin/env bash
set -euo pipefail

cmd="${1:?usage: scripts/session-state.sh create|list|clean [--apply] [id]}"
apply="0"
id="${2:-}"

if [ "$cmd" = "clean" ] && [ "${2:-}" = "--apply" ]; then
  apply="1"
  id="${3:-}"
fi

mkdir -p .dev-workflow/session

case "$cmd" in
  create)
    id="${id:?usage: scripts/session-state.sh create ID}"
    file=".dev-workflow/session/$id-working.json"
    if [ ! -f "$file" ]; then
      cat > "$file" <<EOF
{
  "id": "$id",
  "flow": "",
  "source": "",
  "changed_files": [],
  "verification": [],
  "review": [],
  "doc_updates": [],
  "open_questions": [],
  "created_at": "$(date +%Y-%m-%dT%H:%M:%S%z)"
}
EOF
    fi
    echo "$file"
    ;;
  list)
    find .dev-workflow/session -type f -name '*-working.json' | sort
    ;;
  clean)
    files="$(find .dev-workflow/session -type f -name '*-working.json' | sort)"
    if [ -z "$files" ]; then
      echo "dev-workflow: 未发现 session 状态文件"
      exit 0
    fi
    if [ "$apply" != "1" ]; then
      echo "dev-workflow: 将清理以下 session 状态文件（预览，不会删除）："
      printf '%s\n' "$files"
      echo
      echo "dev-workflow: 确认已合并到主记录或 strict 文档链路后重新执行本脚本：clean --apply"
      exit 0
    fi
    printf '%s\n' "$files" | while IFS= read -r file; do
      rm -f "$file"
      echo "dev-workflow: 已删除 $file"
    done
    ;;
  *)
    echo "usage: scripts/session-state.sh create|list|clean [--apply] [id]"
    exit 1
    ;;
esac
