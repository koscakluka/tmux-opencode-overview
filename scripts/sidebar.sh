#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

SIDEBAR_DATA=""
LAST_FRAME=""

switch_to_index() {
  local index="$1"
  local selected
  local auto_read

  selected="$(printf '%s\n' "$SIDEBAR_DATA" | awk -F '\t' -v idx="$index" 'NR == idx { print $1 }')"
  [ -n "$selected" ] || return 0

  tmux switch-client -t "$selected"

  auto_read="$(get_tmux_option '@process_sidebar_auto_read' 'on')"
  if [ "$auto_read" = 'on' ]; then
    "$SCRIPT_DIR/mark-read.sh" "$selected" >/dev/null 2>&1 || true
  fi

  refresh_status
}

render() {
  local toggle_key
  local select_key
  local data
  local frame

  toggle_key="$(get_tmux_option "@process_sidebar_toggle_key" "I")"
  select_key="$(get_tmux_option "@process_sidebar_select_key" "G")"
  printf -v frame 'OpenCode Sidebar\ntoggle:%s  select:%s\n\n' "$toggle_key" "$select_key"

  data="$($SCRIPT_DIR/collect.sh)"
  SIDEBAR_DATA="$data"

  if [ -z "$data" ]; then
    frame+=$'No matching sessions.\n\n'
    frame+="Notify: ${SCRIPT_DIR}/notify.sh <session> [message]\n"
    frame+=$'Keys: s selector, q hide\n'
    if [ "$frame" != "$LAST_FRAME" ]; then
      printf '\033[H\033[2J%s' "$frame"
      LAST_FRAME="$frame"
    fi
    return
  fi

  frame+="$(printf '%s\n' "$data" | awk -F '\t' '
    {
      session = $1
      unread = $3 + 0
      running = $4 + 0

      marker = "-"
      if (unread > 0 && running == 1) {
        marker = "!*"
      } else if (unread > 0) {
        marker = "!"
      } else if (running == 1) {
        marker = "*"
      }

      printf "%-2d %-24s %-2s\n", NR, session, marker
    }

    END {
      print ""
      print "Markers: ! unread update, * running OpenCode"
      print "Newest updates are shown first; then newest session creation."
      print "Keys: 1-9 jump, s selector, q hide"
    }
  ')"

  if [ "$frame" != "$LAST_FRAME" ]; then
    printf '\033[H\033[2J%s' "$frame"
    LAST_FRAME="$frame"
  fi
}

handle_key() {
  local key="$1"

  case "$key" in
    [1-9])
      switch_to_index "$key"
      ;;
    s|S)
      "$SCRIPT_DIR/select.sh" >/dev/null 2>&1 || true
      ;;
    q|Q)
      "$SCRIPT_DIR/toggle.sh" >/dev/null 2>&1 || true
      exit 0
      ;;
    *)
      ;;
  esac
}

main() {
  local refresh
  local key

  refresh="$(get_tmux_option "@process_sidebar_refresh" "2")"
  case "$refresh" in
    ''|*[!0-9.]*) refresh="2" ;;
  esac

  while :; do
    render
    if IFS= read -r -s -n1 -t "$refresh" key; then
      handle_key "$key"
    fi
  done
}

main "$@"
