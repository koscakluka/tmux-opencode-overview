#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

parse_pending_payload() {
  local payload="$1"
  local out_session_var="$2"
  local out_message_var="$3"
  local session_value
  local message_value
  local remainder

  session_value=''
  message_value="$payload"

  case "$payload" in
    --session=*)
      remainder="${payload#--session=}"
      if [[ "$remainder" == *" --msg="* ]]; then
        session_value="${remainder%% --msg=*}"
        message_value="${remainder#* --msg=}"
      else
        session_value="$remainder"
        message_value=''
      fi
      ;;
  esac

  printf -v "$out_session_var" '%s' "$session_value"
  printf -v "$out_message_var" '%s' "$message_value"
}

main() {
  local session_name
  local pending_message
  local parsed_session
  local parsed_message
  local default_message

  session_name="${1:-}"
  pending_message="$(tmux show-option -gqv '@process_sidebar_pending_message' 2>/dev/null || true)"

  [ -n "$pending_message" ] || exit 0

  tmux set-option -guq '@process_sidebar_pending_message'

  parse_pending_payload "$pending_message" parsed_session parsed_message

  if [ -n "$parsed_session" ]; then
    session_name="$parsed_session"
  fi

  pending_message="$parsed_message"

  if [ -z "$session_name" ]; then
    session_name="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
  fi

  if [ -z "$session_name" ]; then
    session_name="$(tmux list-clients -F '#{session_name}' 2>/dev/null | awk 'NR == 1 { print; exit }')"
  fi

  [ -n "$session_name" ] || exit 0
  tmux has-session -t "$session_name" >/dev/null 2>&1 || exit 0

  default_message="$(tmux show-option -gqv '@process_sidebar_default_message' 2>/dev/null || true)"
  if [ -z "$pending_message" ]; then
    pending_message="$default_message"
  fi

  "$SCRIPT_DIR/notify.sh" "$session_name" "$pending_message" >/dev/null 2>&1 || true
}

main "$@"
