# Cursor Agent Notify — Reference

[中文参考手册](reference-cn.md)

Source repo: [cursor-agent-notify](https://github.com/Syes-K/cursor-agent-notify)

## hooks.json

User-level path: `~/.cursor/hooks.json` (relative paths resolve from `~/.cursor/`)

```json
{
  "version": 1,
  "hooks": {
    "stop": [{ "command": "./hooks/agent-notify.sh" }],
    "subagentStop": [{ "command": "./hooks/agent-notify.sh" }],
    "preToolUse": [{
      "command": "./hooks/agent-notify.sh",
      "matcher": "ApplyPatch"
    }],
    "beforeShellExecution": [{ "command": "./hooks/agent-notify.sh" }],
    "beforeMCPExecution": [{ "command": "./hooks/agent-notify.sh" }]
  }
}
```

Optional: add `sessionStart` under `hooks` and set `play_on_session_start: true` in the config.

Approval Ping strategy: `ApplyPatch` via `preToolUse`; shell skips read-only patterns; MCP via `beforeMCPExecution`. `Write`, `StrReplace`, `Grep`, `Task`, etc. are not hooked.

## notify-config.json fields

| Path | Type | Default | Description |
|------|------|---------|-------------|
| `sounds.agent_turn_complete` | string \| null | Glass.aiff | Agent turn finished |
| `sounds.agent_error` | string \| null | Basso.aiff | Error / aborted |
| `sounds.approval_needed` | string \| null | Ping.aiff | Waiting for Accept |
| `sounds.subagent_complete` | string \| null | Pop.aiff | Subagent done |
| `sounds.session_start` | string \| null | null | Session started |
| `notifications.enabled` | bool | true | Master switch |
| `notifications.activate_on_click` | bool | true | Click notification to focus Cursor |
| `notifications.app_bundle_id` | string | `com.todesktop.230313mzl4w4u92` | Cursor bundle ID |
| `notifications.group_id` | string \| null | `cursor-agent` | terminal-notifier group |
| `notifications.messages.*` | string | see example | Notification body text |
| `behavior.play_on_stop` | bool | true | |
| `behavior.play_on_subagent_stop` | bool | true | |
| `behavior.play_on_session_start` | bool | false | |
| `behavior.notify_on_file_tools` | bool | true | Ping on `ApplyPatch` |
| `behavior.notify_on_shell_approval` | bool | true | Ping on shell unless `shell_skip_notify_patterns` matches |
| `behavior.notify_on_mcp_approval` | bool | true | Ping on MCP calls |
| `behavior.notify_cooldown_seconds` | number | 5 | Debounce duplicate alerts |
| `behavior.shell_skip_notify_patterns` | string[] | see example | Read-only shell commands — no Ping |

Set `CURSOR_NOTIFY_CONFIG` to override the config file path.

## terminal-notifier

Typical install path: `/usr/local/bin/terminal-notifier` (2.0.0+)

### How this project uses it

| Capability | Usage in script |
|------------|-----------------|
| `-activate <bundle_id>` | When `activate_on_click: true`, click returns to Cursor |
| `-sender <bundle_id>` | When `activate_on_click: false`, show Cursor icon |
| `-group <id>` | `group_id` — only the latest notification per group |
| `-title` / `-message` | Text from config |
| `-sound` | Not used (sounds play via `afplay` with custom paths) |

**Note:** `-sender` and `-activate` cannot be used together; the script picks one based on config.

### Other flags (not wired in the script — extend as needed)

```bash
terminal-notifier -message "PR ready" -open "https://github.com/..."
terminal-notifier -remove cursor-agent
terminal-notifier -list ALL
```

## Troubleshooting

| Symptom | Check |
|---------|-------|
| No response at all | Hooks loaded? `chmod +x agent-notify.sh` |
| Sound but no notification | System notification permission; terminal-notifier alerts enabled |
| Click does not return to Cursor | `which terminal-notifier`; `activate_on_click` |
| Too many notifications | Add patterns to `shell_skip_notify_patterns`; set `notify_on_mcp_approval: false` |
| Hook reports invalid JSON | Script must end with valid JSON (`{}` or `permission`) |
| No Ping on Blocked | `preToolUse` matcher + `notify_on_file_tools: true`? |

## Development & release

```bash
cd ~/Projects/cursor-agent-notify
./install.sh          # sync to ~/.cursor
./bin/test.sh complete
git init && git add . && git commit -m "Initial commit"
```
