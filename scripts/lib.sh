#!/usr/bin/env bash

get_tmux_option() {
  local key="$1"
  local fallback="$2"
  local value

  value="$(tmux show-option -gqv "$key" 2>/dev/null || true)"
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$fallback"
  fi
}

get_state_dir() {
  get_tmux_option "@process_sidebar_state_dir" "$HOME/.local/state/tmux-process-sidebar"
}

get_state_file() {
  local state_file
  local state_dir

  state_file="$(tmux show-option -gqv "@process_sidebar_state_file" 2>/dev/null || true)"
  if [ -n "$state_file" ]; then
    printf '%s\n' "$state_file"
    return
  fi

  state_dir="$(get_state_dir)"
  printf '%s/updates.tsv\n' "$state_dir"
}

ensure_state_file() {
  local state_file
  local parent_dir

  state_file="$(get_state_file)"
  parent_dir="$(dirname -- "$state_file")"

  mkdir -p "$parent_dir"
  touch "$state_file"

  printf '%s\n' "$state_file"
}

refresh_status() {
  local client
  local clients

  clients="$(tmux list-clients -F '#{client_tty}' 2>/dev/null || true)"
  [ -n "$clients" ] || return 0

  printf '%s\n' "$clients" | while IFS= read -r client; do
    [ -n "$client" ] || continue
    tmux refresh-client -S -t "$client" >/dev/null 2>&1 || true
  done
}
