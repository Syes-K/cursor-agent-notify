#!/usr/bin/env bash
# Test notifications without waiting for a real agent event.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${CURSOR_NOTIFY_SCRIPT:-$HOME/.cursor/hooks/agent-notify.sh}"

if [[ ! -x "$SCRIPT" ]]; then
  SCRIPT="$ROOT/scripts/agent-notify.sh"
  chmod +x "$SCRIPT"
fi

case "${1:-complete}" in
  complete|done|stop)
    echo '{"hook_event_name":"stop","status":"completed"}' | "$SCRIPT"
    echo "Sent: agent turn complete (Glass)"
    ;;
  error)
    echo '{"hook_event_name":"stop","status":"error"}' | "$SCRIPT"
    echo "Sent: agent error (Basso)"
    ;;
  approval|blocked|shell)
    echo '{"hook_event_name":"beforeShellExecution","command":"git commit -m test"}' | "$SCRIPT"
    echo "Sent: approval needed (Ping)"
    ;;
  subagent)
    echo '{"hook_event_name":"subagentStop","status":"completed"}' | "$SCRIPT"
    echo "Sent: subagent complete (Pop)"
    ;;
  *)
    echo "Usage: $0 {complete|error|approval|subagent}"
    exit 1
    ;;
esac
