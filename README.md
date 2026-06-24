# cursor-agent-notify

Sound and macOS notifications when the [Cursor](https://cursor.com) agent finishes, waits for your **Accept**, or errors — so you can switch to other apps without missing the moment to come back.

Uses [Cursor Hooks](https://cursor.com/docs/agent/hooks) + [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) (click notification → focus Cursor).

## Features

| Event | When | Sound (default) |
|-------|------|-----------------|
| Agent turn done | `stop` completed | Glass |
| Needs Accept / Blocked | ApplyPatch, shell (non-readonly), MCP | Ping |
| Agent error | `stop` error/aborted | Basso |
| Subagent done | `subagentStop` | Pop |

- Click notification to return to Cursor (`terminal-notifier -activate`)
- Notification grouping (`-group cursor-agent`) — only latest shown
- Configurable sounds, messages, and behavior via JSON

## Requirements

- macOS 10.10+
- [Cursor](https://cursor.com) with Hooks enabled
- `jq` — `brew install jq`
- `terminal-notifier` (recommended) — `brew install terminal-notifier`

## Install

```bash
git clone https://github.com/Syes-K/cursor-agent-notify.git
cd cursor-agent-notify
./install.sh
```

This installs to `~/.cursor/` (user-level, all projects):

```
~/.cursor/hooks/agent-notify.sh
~/.cursor/hooks/notify-config.json
~/.cursor/hooks.json
~/.cursor/skills/cursor-agent-notify/   # optional Cursor skill docs
```

Then allow notifications for **terminal-notifier** in System Settings, restart Cursor, and click **Allow hooks/** on first run.

## Test

```bash
./bin/test.sh complete    # agent finished
./bin/test.sh approval    # blocked / accept
./bin/test.sh error
./bin/test.sh subagent
```

## Configure

Edit `~/.cursor/hooks/notify-config.json` (copy from `notify-config.example.json`):

```json
{
  "notifications": {
    "activate_on_click": true,
    "group_id": "cursor-agent"
  },
  "behavior": {
    "notify_on_file_tools": true,
    "notify_on_shell_approval": true,
    "notify_on_mcp_approval": true,
    "play_on_stop": true
  }
}
```

See [docs/reference.md](docs/reference.md) for all options.

### Approval notifications (Ping)

Cursor has no hook for “already blocked”. We approximate your intent:

| Category | When it Pings | Hook |
|----------|----------------|------|
| **ApplyPatch** | Multi-file patch (unified diff) | `preToolUse` + matcher |
| **Shell** | Commands that don’t match `shell_skip_notify_patterns` (read-only / status checks are skipped) | `beforeShellExecution` |
| **MCP** | Every MCP call (usually needs Accept) | `beforeMCPExecution` |

`Grep`, `Glob`, `Task`, `SemanticSearch`, etc. are **not** notified on use.

Auto-approved file edits or allowlisted shell commands may still Ping — hooks fire **before** Cursor decides. Tune `shell_skip_notify_patterns` in `notify-config.json` if a safe command still alerts.

```json
"preToolUse": [{
  "command": "./hooks/agent-notify.sh",
  "matcher": "ApplyPatch"
}]
```

## Uninstall

```bash
rm ~/.cursor/hooks/agent-notify.sh
rm ~/.cursor/hooks/notify-config.json
rm -rf ~/.cursor/skills/cursor-agent-notify
# Manually remove cursor-agent-notify entries from ~/.cursor/hooks.json
```

## Project layout

```
cursor-agent-notify/
├── install.sh
├── hooks.json.example
├── notify-config.example.json
├── scripts/agent-notify.sh
├── bin/test.sh
├── docs/reference.md
└── skill/SKILL.md          # Cursor agent skill (installed by install.sh)
```

## Limitations

- No dedicated hook for “already blocked” — `ApplyPatch` always Pings; shell uses skip patterns to approximate “needs confirmation”; MCP always Pings
- First **Allow hooks/** must be clicked in Cursor (chicken-and-egg)
- `stop` + `completed` covers both “done” and “waiting for your reply”
- Cloud Agents may not support `stop` hooks

## License

MIT — see [LICENSE](LICENSE).

中文说明：[README-cn.md](README-cn.md)
