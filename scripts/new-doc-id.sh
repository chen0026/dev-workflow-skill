#!/usr/bin/env bash
set -euo pipefail

type="${1:?usage: new-doc-id.sh DEV|ADR|OPS short-title}"
title="${2:?usage: new-doc-id.sh DEV|ADR|OPS short-title}"

case "$type" in
  DEV|ADR|OPS) ;;
  *)
    echo "dev-workflow: TYPE 必须是 DEV/ADR/OPS"
    exit 1
    ;;
esac

slug="$(printf '%s' "$title" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
  | cut -c1-48)"

[ -n "$slug" ] || slug="work-item"

timestamp="$(date +%Y%m%d-%H%M%S)"
random_id="$(printf '%04x' "$((RANDOM % 65536))")"
printf '%s-%s-%s-%s\n' "$type" "$timestamp" "$random_id" "$slug"
