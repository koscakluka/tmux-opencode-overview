#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

main() {
  tmux set-option -gq '@process_sidebar_mode' 'both'
  refresh_status
  tmux display-message 'OpenCode sidebar mode is fixed: both'
}

main "$@"
