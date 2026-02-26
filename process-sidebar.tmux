#!/usr/bin/env bash

set -euo pipefail

PLUGIN_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

get_option() {
  tmux show-option -gqv "$1" 2>/dev/null || true
}

set_default() {
  local key="$1"
  local value="$2"
  local current
  current="$(get_option "$key")"
  if [ -z "$current" ]; then
    tmux set-option -gq "$key" "$value"
  fi
}

main() {
  set_default "@process_sidebar_pattern" "opencode|codex"
  set_default "@process_sidebar_mode" "both"
  set_default "@process_sidebar_width" "42"
  set_default "@process_sidebar_side" "right"
  set_default "@process_sidebar_refresh" "2"
  set_default "@process_sidebar_enabled" "off"
  set_default "@process_sidebar_sticky" "on"
  set_default "@process_sidebar_toggle_key" "I"
  set_default "@process_sidebar_toggle_key_alt" "i"
  set_default "@process_sidebar_select_key" "G"
  set_default "@process_sidebar_auto_read" "on"
  set_default "@process_sidebar_indicator_hide_zero" "off"
  set_default "@process_sidebar_state_dir" "$HOME/.local/state/tmux-process-sidebar"

  tmux set-option -gq "@process_sidebar_mode" "both"

  local toggle_key
  local toggle_key_alt
  local select_key
  local legacy_mode_key

  toggle_key="$(get_option "@process_sidebar_toggle_key")"
  toggle_key_alt="$(get_option "@process_sidebar_toggle_key_alt")"
  select_key="$(get_option "@process_sidebar_select_key")"

  if [ -n "$toggle_key" ]; then
    tmux bind-key "$toggle_key" run-shell "$PLUGIN_DIR/scripts/toggle.sh"
  fi

  if [ -n "$toggle_key_alt" ] && [ "$toggle_key_alt" != "$toggle_key" ]; then
    tmux bind-key "$toggle_key_alt" run-shell "$PLUGIN_DIR/scripts/toggle.sh"
  fi

  if [ -n "$select_key" ]; then
    tmux bind-key "$select_key" run-shell "$PLUGIN_DIR/scripts/select.sh"
  fi

  legacy_mode_key="$(tmux list-keys -T prefix 2>/dev/null | awk -v script="$PLUGIN_DIR/scripts/toggle-mode.sh" '$1 == "bind-key" && $2 == "-T" && $3 == "prefix" && $5 == "run-shell" && $6 == script { print $4; exit }')"
  if [ -n "$legacy_mode_key" ]; then
    tmux unbind-key "$legacy_mode_key" >/dev/null 2>&1 || true
  fi

  local indicator_cmd
  local status_right
  local new_status_right

  indicator_cmd="#($PLUGIN_DIR/scripts/indicator.sh)"
  status_right="$(tmux show-option -gqv status-right 2>/dev/null || true)"

  case "$status_right" in
    *"$PLUGIN_DIR/scripts/indicator.sh"*)
      ;;
    "")
      tmux set-option -gq status-right "$indicator_cmd"
      ;;
    *)
      new_status_right="$status_right $indicator_cmd"
      tmux set-option -gq status-right "$new_status_right"
      ;;
  esac

  tmux set-hook -g client-session-changed "run-shell '$PLUGIN_DIR/scripts/ensure.sh \"#{client_tty}\"'"
  tmux set-hook -g client-attached "run-shell '$PLUGIN_DIR/scripts/ensure.sh \"#{client_tty}\"'"
  tmux set-hook -g after-select-window "run-shell '$PLUGIN_DIR/scripts/ensure.sh'"
  tmux set-hook -g after-new-window "run-shell '$PLUGIN_DIR/scripts/ensure.sh'"

  "$PLUGIN_DIR/scripts/ensure.sh" >/dev/null 2>&1 || true
}

main "$@"
