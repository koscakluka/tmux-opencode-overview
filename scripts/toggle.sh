#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

pane_exists() {
  local pane_id="$1"
  local actual

  [ -n "$pane_id" ] || return 1
  actual="$(tmux display-message -p -t "$pane_id" '#{pane_id}' 2>/dev/null || true)"
  [ "$actual" = "$pane_id" ]
}

list_sidebar_panes() {
  tmux list-panes -a -F '#{pane_id} #{pane_title}' 2>/dev/null |
    awk '$2 == "opencode-sidebar" { print $1 }'
}

main() {
  local pane_id
  local pane
  local existing
  local width
  local side
  local window_id
  local sidebar_script

  existing="$(list_sidebar_panes || true)"
  if [ -n "$existing" ]; then
    printf '%s\n' "$existing" | while IFS= read -r pane; do
      [ -n "$pane" ] || continue
      tmux kill-pane -t "$pane" >/dev/null 2>&1 || true
    done
    tmux set-option -guq '@process_sidebar_pane_id'
    tmux set-option -gq '@process_sidebar_enabled' 'off'
    refresh_status
    tmux display-message 'OpenCode sidebar hidden'
    exit 0
  fi

  pane_id="$(tmux show-option -gqv '@process_sidebar_pane_id' 2>/dev/null || true)"
  if pane_exists "$pane_id"; then
    tmux kill-pane -t "$pane_id"
    tmux set-option -guq '@process_sidebar_pane_id'
    tmux set-option -gq '@process_sidebar_enabled' 'off'
    refresh_status
    tmux display-message 'OpenCode sidebar hidden'
    exit 0
  fi

  width="$(get_tmux_option '@process_sidebar_width' '42')"
  side="$(get_tmux_option '@process_sidebar_side' 'right')"
  sidebar_script="$SCRIPT_DIR/sidebar.sh"
  window_id="$(tmux display-message -p '#{window_id}' 2>/dev/null || true)"

  if [ -z "$window_id" ]; then
    window_id="$(tmux list-clients -F '#{window_id}' 2>/dev/null | awk 'NR == 1 { print; exit }')"
  fi

  [ -n "$window_id" ] || exit 0

  case "$width" in
    ''|*[!0-9]*) width='42' ;;
  esac

  if [ "$side" = 'left' ]; then
    pane_id="$(tmux split-window -d -P -F '#{pane_id}' -t "$window_id" -h -b -l "$width" "$sidebar_script")"
  else
    pane_id="$(tmux split-window -d -P -F '#{pane_id}' -t "$window_id" -h -l "$width" "$sidebar_script")"
  fi

  tmux set-option -gq '@process_sidebar_pane_id' "$pane_id"
  tmux set-option -gq '@process_sidebar_enabled' 'on'
  tmux select-pane -t "$pane_id" -T 'opencode-sidebar' >/dev/null 2>&1 || true
  refresh_status
  tmux display-message 'OpenCode sidebar shown'
}

main "$@"
