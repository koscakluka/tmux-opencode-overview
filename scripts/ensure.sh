#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

window_has_sidebar() {
  local window_id="$1"

  tmux list-panes -t "$window_id" -F '#{pane_title}' 2>/dev/null |
    awk '$1 == "opencode-sidebar" { found=1 } END { exit(found ? 0 : 1) }'
}

main() {
  local client_tty
  local enabled
  local sticky
  local width
  local side
  local window_id
  local pane_id

  client_tty="${1:-}"
  enabled="$(get_tmux_option '@process_sidebar_enabled' 'off')"
  sticky="$(get_tmux_option '@process_sidebar_sticky' 'on')"

  [ "$enabled" = 'on' ] || exit 0
  [ "$sticky" = 'on' ] || exit 0

  if [ -n "$client_tty" ]; then
    window_id="$(tmux display-message -p -t "$client_tty" '#{window_id}' 2>/dev/null || true)"
  else
    window_id="$(tmux display-message -p '#{window_id}' 2>/dev/null || true)"
  fi

  [ -n "$window_id" ] || exit 0

  if window_has_sidebar "$window_id"; then
    exit 0
  fi

  width="$(get_tmux_option '@process_sidebar_width' '42')"
  side="$(get_tmux_option '@process_sidebar_side' 'right')"
  case "$width" in
    ''|*[!0-9]*) width='42' ;;
  esac

  if [ "$side" = 'left' ]; then
    pane_id="$(tmux split-window -d -P -F '#{pane_id}' -t "$window_id" -h -b -l "$width" "$SCRIPT_DIR/sidebar.sh")"
  else
    pane_id="$(tmux split-window -d -P -F '#{pane_id}' -t "$window_id" -h -l "$width" "$SCRIPT_DIR/sidebar.sh")"
  fi

  tmux set-option -gq '@process_sidebar_pane_id' "$pane_id"
  tmux select-pane -t "$pane_id" -T 'opencode-sidebar' >/dev/null 2>&1 || true
  refresh_status
}

main "$@"
