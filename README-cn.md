# cursor-agent-notify

Cursor Agent 完成、等你点 **Accept**、或出错时，播放音效并弹出 macOS 通知；配合 `terminal-notifier` 可**点击通知回到 Cursor**。

[English README](README.md)

## 功能

| 场景 | 触发时机 | 默认音效 |
|------|----------|----------|
| Agent 跑完等你回复 | `stop` completed | Glass |
| Blocked / 待 Accept | Shell、Write、MCP | Ping |
| 出错 / 中止 | `stop` error | Basso |
| 子任务完成 | `subagentStop` | Pop |

## 安装

```bash
git clone https://github.com/Syes-K/cursor-agent-notify.git
cd cursor-agent-notify
./install.sh
```

依赖：

```bash
brew install jq terminal-notifier
```

然后在 **系统设置 → 通知 → terminal-notifier** 允许通知，重启 Cursor，首次运行时点 **Allow hooks/**。

## 测试

```bash
./bin/test.sh complete    # 模拟 Agent 完成
./bin/test.sh approval    # 模拟待确认
```

## 配置

编辑 `~/.cursor/hooks/notify-config.json`，示例见 `notify-config.example.json`。

完整字段说明：[docs/reference.md](docs/reference.md)

## 项目结构

```
cursor-agent-notify/
├── install.sh                 # 安装到 ~/.cursor
├── scripts/agent-notify.sh    # Hook 脚本
├── hooks.json.example
├── notify-config.example.json
├── bin/test.sh
├── docs/reference.md
└── skill/SKILL.md
```

## 卸载

```bash
rm ~/.cursor/hooks/agent-notify.sh ~/.cursor/hooks/notify-config.json
rm -rf ~/.cursor/skills/cursor-agent-notify
# 手动从 ~/.cursor/hooks.json 删除相关 hook 条目
```

## License

MIT
