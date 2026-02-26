#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

main() {
  local session
  local state_file
  local tmp_file

  session="${1:-}"
  if [ -z "$session" ]; then
    session="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
  fi

  [ -n "$session" ] || exit 0

  state_file="$(ensure_state_file)"
  tmp_file="$(mktemp)"

  awk -F '\t' -v OFS='\t' -v target="$session" '
    BEGIN {
      updated = 0
    }

    NF >= 3 {
      if ($1 == target) {
        $3 = 0
        updated = 1
      }
      print $0
      next
    }

    {
      print $0
    }

    END {
      if (!updated) {
        # no-op if missing
      }
    }
  ' "$state_file" > "$tmp_file"

  mv "$tmp_file" "$state_file"
  refresh_status
}

main "$@"
