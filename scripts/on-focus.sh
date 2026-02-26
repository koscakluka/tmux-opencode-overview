#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

main() {
  local client_tty
  local session_name

  client_tty="${1:-}"
  session_name="${2:-}"

  "$SCRIPT_DIR/ensure.sh" "$client_tty" >/dev/null 2>&1 || true

  if [ -n "$session_name" ]; then
    "$SCRIPT_DIR/mark-read.sh" "$session_name" >/dev/null 2>&1 || true
  fi
}

main "$@"
