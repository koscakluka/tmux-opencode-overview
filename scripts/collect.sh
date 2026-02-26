#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

pattern="$(get_tmux_option "@process_sidebar_pattern" "opencode|codex")"
state_file="$(ensure_state_file)"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

tmux list-sessions -F '#{session_name} #{session_created}' 2>/dev/null |
  awk '{printf "%s\t%s\n", $1, $2}' > "$tmp_dir/sessions.tsv"
if [ ! -s "$tmp_dir/sessions.tsv" ]; then
  exit 0
fi

tmux list-panes -a -F '#{session_name} #{pane_pid}' 2>/dev/null |
  awk '{printf "%s\t%s\n", $1, $2}' > "$tmp_dir/panes.tsv"

if [ -s "$tmp_dir/panes.tsv" ]; then
  ps -axo pid=,ppid=,command= |
    awk '{pid=$1; ppid=$2; $1=""; $2=""; sub(/^[[:space:]]+/, "", $0); printf "%s\t%s\t%s\n", pid, ppid, $0}' > "$tmp_dir/processes.tsv"

  awk -F '\t' -v OFS='\t' -v pattern="$pattern" '
    FILENAME == ARGV[1] {
      if ($2 ~ /^[0-9]+$/) {
        roots[$2] = $1
      }
      next
    }

    FILENAME == ARGV[2] {
      pid = $1
      ppid = $2
      cmd = $3
      parent[pid] = ppid
      command[pid] = cmd
      next
    }

    END {
      for (pid in command) {
        if (command[pid] ~ pattern) {
          cur = pid
          guard = 0
          while (cur != "" && guard < 500) {
            if (cur in roots) {
              matched[roots[cur]] = 1
              break
            }

            if (!(cur in parent)) {
              break
            }

            next_cur = parent[cur]
            if (next_cur == cur) {
              break
            }

            cur = next_cur
            guard++
          }
        }
      }

      for (session in matched) {
        print session
      }
    }
  ' "$tmp_dir/panes.tsv" "$tmp_dir/processes.tsv" | sort -u > "$tmp_dir/instances.tsv"
else
  : > "$tmp_dir/instances.tsv"
fi

cp "$state_file" "$tmp_dir/updates.tsv"

awk -F '\t' -v OFS='\t' \
  -v sessions_file="$tmp_dir/sessions.tsv" \
  -v instances_file="$tmp_dir/instances.tsv" \
  -v updates_file="$tmp_dir/updates.tsv" '
    FILENAME == sessions_file {
      created[$1] = $2 + 0
      next
    }

    FILENAME == instances_file {
      if ($1 != "") {
        has_instance[$1] = 1
      }
      next
    }

    FILENAME == updates_file {
      if (NF >= 3) {
        last_update[$1] = $2 + 0
        unread[$1] = $3 + 0
        if (NF >= 4) {
          last_message[$1] = $4
        } else {
          last_message[$1] = ""
        }
      }
      next
    }

    END {
      for (session in created) {
        instance = (session in has_instance) ? 1 : 0
        updated_at = (session in last_update) ? last_update[session] : 0
        unread_count = (session in unread) ? unread[session] : 0
        message = (session in last_message) ? last_message[session] : ""

        include = (instance || unread_count > 0)

        if (include) {
          if (message != "") {
            printf "%s\t%d\t%d\t%d\t%d\t%s\n", session, updated_at, unread_count, instance, created[session], message
          } else {
            printf "%s\t%d\t%d\t%d\t%d\n", session, updated_at, unread_count, instance, created[session]
          }
        }
      }
    }
  ' "$tmp_dir/sessions.tsv" "$tmp_dir/instances.tsv" "$tmp_dir/updates.tsv" |
  sort -t "$(printf '\t')" -k2,2nr -k5,5nr -k1,1
