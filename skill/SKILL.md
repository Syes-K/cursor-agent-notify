---
name: cursor-agent-notify
description: >-
  Configure Cursor agent state notifications (audio + macOS alerts) via user hooks.
  Use when the user wants sound or notification when the agent finishes, pauses for
  Accept/confirmation, errors, or when subagents complete. Triggers on agent notify,
  hooks, terminal-notifier, notification, reminder, sound, completion alert, Blocked, Accept.
disable-model-invocation: true
---

# Cursor Agent State Notifications

Source & install: [cursor-agent-notify](https://github.com/Syes-K/cursor-agent-notify) · [README.md](https://github.com/Syes-K/cursor-agent-notify/blob/main/README.md)

Play sounds and show macOS notifications when the agent finishes, waits for Accept, or errors. With `terminal-notifier`, clicking a notification returns focus to Cursor.

## Install / update

```bash
cd ~/Projects/cursor-agent-notify
./install.sh
```

Install targets: `~/.cursor/hooks/`, `~/.cursor/hooks.json`, `~/.cursor/skills/cursor-agent-notify/`

## State ↔ events

| What you notice | Hook event | Sound |
|-----------------|------------|-------|
| Agent done, waiting for your reply | `stop` (`completed`) | Glass |
| Blocked, waiting for Accept | `beforeShellExecution` | Ping |
| ApplyPatch (multi-file patch) | `preToolUse` | Ping |
| MCP pending approval | `beforeMCPExecution` | Ping |
| Subagent finished | `subagentStop` | Pop |

## Test

```bash
~/Projects/cursor-agent-notify/bin/test.sh complete
~/Projects/cursor-agent-notify/bin/test.sh approval
```

## Configure

`~/.cursor/hooks/notify-config.json` — see `notify-config.example.json` in the repo.

Full field reference: [docs/reference.md](../docs/reference.md) (copied to `reference.md` in the skill dir after install).

## When maintaining as an agent

- Edit `scripts/agent-notify.sh` in the repo, then run `./install.sh` to sync to `~/.cursor`
- Do not edit only `~/.cursor` without syncing back to the repo (avoids drift from GitHub)
