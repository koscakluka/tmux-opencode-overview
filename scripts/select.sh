#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

format_for_picker() {
  local now
  now="$(date +%s)"

  awk -F '\t' -v OFS='\t' -v now="$now" '
    function age(ts, delta) {
      if (ts <= 0) {
        return "never"
      }

      delta = now - ts
      if (delta < 60) {
        return delta "s"
      }
      if (delta < 3600) {
        return int(delta / 60) "m"
      }
      if (delta < 86400) {
        return int(delta / 3600) "h"
      }
      return int(delta / 86400) "d"
    }

    {
      marker = "-"
      if (($3 + 0) > 0 && ($4 + 0) == 1) {
        marker = "!*"
      } else if (($3 + 0) > 0) {
        marker = "!"
      } else if (($4 + 0) == 1) {
        marker = "*"
      }

      printf "%s\t%s\t%s\n", $1, marker, age($2 + 0)
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
      fzf --delimiter='\t' --with-nth=1,2,3 --prompt='OpenCode session> ' --height=80% --reverse |
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
