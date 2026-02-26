#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

main() {
  local session
  local message
  local now
  local state_file
  local tmp_file

  session="${1:-}"
  shift || true

  if [ -z "$session" ]; then
    session="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
  fi

  [ -n "$session" ] || {
    printf 'notify.sh: session is required when not running inside tmux\n' >&2
    exit 1
  }

  if [ "$#" -gt 0 ]; then
    message="$*"
  else
    message='update'
  fi

  message="$(printf '%s' "$message" | tr '\t\n' '  ')"
  now="$(date +%s)"

  state_file="$(ensure_state_file)"
  tmp_file="$(mktemp)"

  awk -F '\t' -v OFS='\t' -v target="$session" -v ts="$now" -v msg="$message" '
    BEGIN {
      updated = 0
    }

    NF >= 1 {
      if ($1 == target) {
        print target, ts, 1, msg
        updated = 1
        next
      }
      print $0
      next
    }

    {
      print $0
    }

    END {
      if (!updated) {
        print target, ts, 1, msg
      }
    }
  ' "$state_file" > "$tmp_file"

  mv "$tmp_file" "$state_file"

  refresh_status
}

main "$@"
