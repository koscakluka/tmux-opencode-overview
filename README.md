# process-sidebar

tmux sidebar plugin for tracking OpenCode activity across sessions.

## Features

- Sidebar with sessions that match a process pattern (`opencode|codex` by default).
- Sidebar includes sessions that have a matching running process and/or unread OpenCode notifications.
- Unread updates show as an orange `*` next to the session name and clear when the session is focused.
- Notification messages (when provided) are shown on the line under the session name.
- Session ordering:
  - newest notification first
  - then newest session creation time
- Selection flow (`fzf`): quickly switch to a session from the sorted list.
- Status indicator (`OC !N`): shows unread notification count.

## Options

All options are global tmux options.

- `@process_sidebar_pattern` (default: `opencode|codex`)
- `@process_sidebar_width` (default: `42`)
- `@process_sidebar_side` (default: `right`, supports `left`)
- `@process_sidebar_refresh` (default: `2`)
- `@process_sidebar_enabled` (default: `off`, set by toggle script)
- `@process_sidebar_sticky` (default: `on`, keep sidebar open when session changes)
- `@process_sidebar_toggle_key` (default: `I`)
- `@process_sidebar_toggle_key_alt` (default: `i`)
- `@process_sidebar_select_key` (default: `g`)
- `@process_sidebar_auto_read` (default: `on`)
- `@process_sidebar_indicator_hide_zero` (default: `off`)
- `@process_sidebar_default_message` (default: `update`)
- `@process_sidebar_state_dir` (default: `~/.local/state/tmux-process-sidebar`)
- `@process_sidebar_state_file` (optional explicit file path)

## Notify API

Use this command from OpenCode or a wrapper to signal an update:

```bash
~/.config/tmux/plugins/process-sidebar/scripts/notify.sh [session_name] [message]
```

From tmux command prompt, you can also run:

```tmux
oc-notify
oc-notify-msg "custom message"
```

Or directly from shell:

```bash
tmux oc-notify
tmux oc-notify-msg "custom message"
```

- If `session_name` is omitted, it uses the current tmux session.
- `message` is optional.
- `oc-notify` uses `@process_sidebar_default_message`.
- Notification state is stored in `updates.tsv`.

## Keys

Default key bindings after plugin load:

- `prefix + I`: toggle sidebar pane
- `prefix + i`: toggle sidebar pane (alternate)
- `prefix + g`: choose a session and switch client

## Sidebar pane controls

When your cursor is inside the sidebar pane:

- `1`..`9`: jump directly to that row's session
- `s`: open the interactive session selector (`fzf`)
- `q`: hide sidebar
