#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

main() {
  local session_name
  local message

  message="${1:-}"
  if [ -z "$message" ]; then
    message="$(tmux show-option -gqv '@process_sidebar_default_message' 2>/dev/null || true)"
    [ -n "$message" ] || message='update'
  fi

  if [ -n "${TMUX:-}" ]; then
    session_name="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
  else
    session_name="$(tmux list-clients -F '#{session_name}' 2>/dev/null | awk 'NR == 1 { print; exit }')"
  fi

  [ -n "$session_name" ] || exit 1

  "$SCRIPT_DIR/notify.sh" "$session_name" "$message"
}

main "$@"
