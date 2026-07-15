#!/usr/bin/env bash
set -euo pipefail

type="${1:?usage: scripts/new-doc-id.sh TYPE short-title}"
title="${2:?usage: scripts/new-doc-id.sh TYPE short-title}"

case "$type" in
  DEV|PRD|REQ|TASK|BUG|ACTIVE|CHG|ADR|ACC|OPS|LEGACY) ;;
  *)
    echo "dev-workflow: TYPE 必须是 DEV/PRD/REQ/TASK/BUG/ACTIVE/CHG/ADR/ACC/OPS/LEGACY"
    exit 1
    ;;
esac

stamp="$(date +%Y%m%d-%H%M%S)"

if command -v openssl >/dev/null 2>&1; then
  suffix="$(openssl rand -hex 2)"
else
  suffix="$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"
fi

slug="$(printf '%s' "$title" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"

[ -n "$slug" ] || slug="change"

printf '%s-%s-%s-%s\n' "$type" "$stamp" "$suffix" "$slug"
