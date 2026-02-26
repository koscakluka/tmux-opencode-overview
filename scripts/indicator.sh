#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

main() {
  local state_file
  local hide_zero
  local tmp_sessions
  local unread_count

  state_file="$(ensure_state_file)"
  hide_zero="$(get_tmux_option '@process_sidebar_indicator_hide_zero' 'off')"

  tmp_sessions="$(mktemp)"

  tmux list-sessions -F '#{session_name}' > "$tmp_sessions" 2>/dev/null || true

  unread_count="$(awk -F '\t' '
    FNR == NR {
      active[$1] = 1
      next
    }

    NF >= 3 {
      if (($1 in active) && ($3 + 0) > 0) {
        count++
      }
    }

    END {
      print count + 0
    }
  ' "$tmp_sessions" "$state_file")"

  rm -f "$tmp_sessions"

  if [ "$unread_count" -eq 0 ] && [ "$hide_zero" = 'on' ]; then
    exit 0
  fi

  if [ "$unread_count" -gt 0 ]; then
    printf 'OC !%s' "$unread_count"
  else
    printf 'OC 0'
  fi
}

main "$@"
