#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

format_for_picker() {
  awk -F '\t' -v OFS='\t' '
    BEGIN {
      orange = "\033[38;5;208m"
      reset = "\033[0m"
    }

    {
      session = $1
      updated_at = $2 + 0
      display = session

      if (updated_at > 0) {
        display = orange session "*" reset
      }

      printf "%s\t%-2d %s\n", session, NR, display
    }
  '
}

main() {
  local data
  local selected
  local auto_read

  data="$($SCRIPT_DIR/collect.sh)"

  if [ -z "$data" ]; then
    tmux display-message 'OpenCode sidebar: no matching sessions'
    exit 0
  fi

  if command -v fzf >/dev/null 2>&1; then
    selected="$(printf '%s\n' "$data" |
      format_for_picker |
      fzf --ansi --delimiter='\t' --with-nth=2 --prompt='OpenCode session> ' --height=80% --reverse |
      awk -F '\t' 'NR == 1 { print $1 }' || true)"
  else
    selected="$(printf '%s\n' "$data" | awk -F '\t' 'NR == 1 { print $1 }')"
  fi

  [ -n "$selected" ] || exit 0

  tmux switch-client -t "$selected"

  auto_read="$(get_tmux_option '@process_sidebar_auto_read' 'on')"
  if [ "$auto_read" = 'on' ]; then
    "$SCRIPT_DIR/mark-read.sh" "$selected" >/dev/null 2>&1 || true
  fi

  refresh_status
}

main "$@"
