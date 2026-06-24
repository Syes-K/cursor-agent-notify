# Cursor Agent 通知 — 参考手册

[English reference](reference.md)

源码仓库：[cursor-agent-notify](https://github.com/Syes-K/cursor-agent-notify)

## hooks.json

用户级路径：`~/.cursor/hooks.json`（相对路径以 `~/.cursor/` 为根）

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

可选：在 `hooks` 下加 `sessionStart` 并在配置中设 `play_on_session_start: true`。

待确认 Ping：`ApplyPatch` 走 `preToolUse`；shell 跳过 `shell_skip_notify_patterns` 中的只读命令；MCP 走 `beforeMCPExecution`。`Write`、`StrReplace`、`Grep`、`Task` 等不挂钩。

## notify-config.json 字段

| 路径 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `sounds.agent_turn_complete` | string \| null | Glass.aiff | Agent 完成 |
| `sounds.agent_error` | string \| null | Basso.aiff | 出错 |
| `sounds.approval_needed` | string \| null | Ping.aiff | 待 Accept |
| `sounds.subagent_complete` | string \| null | Pop.aiff | 子任务 |
| `sounds.session_start` | string \| null | null | 会话开始 |
| `notifications.enabled` | bool | true | 总开关 |
| `notifications.activate_on_click` | bool | true | 点击通知聚焦 Cursor |
| `notifications.app_bundle_id` | string | `com.todesktop.230313mzl4w4u92` | Cursor Bundle ID |
| `notifications.group_id` | string \| null | `cursor-agent` | terminal-notifier 分组 |
| `notifications.messages.*` | string | 见 example | 通知正文 |
| `behavior.play_on_stop` | bool | true | |
| `behavior.play_on_subagent_stop` | bool | true | |
| `behavior.play_on_session_start` | bool | false | |
| `behavior.notify_on_file_tools` | bool | true | `ApplyPatch` 时 Ping |
| `behavior.notify_on_shell_approval` | bool | true | shell 未命中 skip 模式时 Ping |
| `behavior.notify_on_mcp_approval` | bool | true | MCP 调用 Ping |
| `behavior.notify_cooldown_seconds` | number | 5 | 防重复响 |
| `behavior.shell_skip_notify_patterns` | string[] | 见 example | 只读 shell — 不 Ping |

环境变量 `CURSOR_NOTIFY_CONFIG` 可覆盖配置文件路径。

## terminal-notifier

已安装路径示例：`/usr/local/bin/terminal-notifier`（2.0.0+）

### 与本方案的关系

| 能力 | 脚本中的用法 |
|------|----------------|
| `-activate <bundle_id>` | `activate_on_click: true` 时，点击回 Cursor |
| `-sender <bundle_id>` | `activate_on_click: false` 时，显示 Cursor 图标 |
| `-group <id>` | `group_id`，同组通知只保留最新一条 |
| `-title` / `-message` | 来自配置文案 |
| `-sound` | 未用（音效由 `afplay` 单独播放，可自定义路径） |

**注意：** `-sender` 与 `-activate` 不能同时使用；脚本已按配置二选一。

### 其他可用参数（未接入脚本，可自行扩展）

```bash
terminal-notifier -message "PR ready" -open "https://github.com/..."
terminal-notifier -remove cursor-agent
terminal-notifier -list ALL
```

## 排错

| 现象 | 检查 |
|------|------|
| 无任何反应 | Hooks 是否加载；`chmod +x agent-notify.sh` |
| 有音效无通知 | 系统通知权限；terminal-notifier 通知开关 |
| 点击不回 Cursor | `which terminal-notifier`；`activate_on_click` |
| 通知太频繁 | 往 `shell_skip_notify_patterns` 加规则；或 `notify_on_mcp_approval: false` |
| Hook 报 invalid JSON | 脚本必须以合法 JSON 结尾（`{}` 或 `permission`） |
| Blocked 无 Ping | `preToolUse` matcher + `notify_on_file_tools: true`？ |

## 开发与发布

```bash
cd ~/Projects/cursor-agent-notify
./install.sh          # 同步到 ~/.cursor
./bin/test.sh complete
git init && git add . && git commit -m "Initial commit"
```
