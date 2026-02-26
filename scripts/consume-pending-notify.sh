#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

main() {
  local session_name
  local pending_message
  local default_message

  session_name="${1:-}"
  pending_message="$(tmux show-option -gqv '@process_sidebar_pending_message' 2>/dev/null || true)"

  [ -n "$pending_message" ] || exit 0

  tmux set-option -guq '@process_sidebar_pending_message'

  if [ -z "$session_name" ]; then
    session_name="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
  fi

  if [ -z "$session_name" ]; then
    session_name="$(tmux list-clients -F '#{session_name}' 2>/dev/null | awk 'NR == 1 { print; exit }')"
  fi

  [ -n "$session_name" ] || exit 0

  default_message="$(tmux show-option -gqv '@process_sidebar_default_message' 2>/dev/null || true)"
  if [ -z "$pending_message" ]; then
    pending_message="$default_message"
  fi

  "$SCRIPT_DIR/notify.sh" "$session_name" "$pending_message" >/dev/null 2>&1 || true
}

main "$@"
