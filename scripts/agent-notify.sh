#!/usr/bin/env bash
# Cursor agent state notifications (audio + macOS notification).
# https://github.com/Syes-K/cursor-agent-notify

set -euo pipefail

CONFIG="${CURSOR_NOTIFY_CONFIG:-$HOME/.cursor/hooks/notify-config.json}"

read_input() {
  cat
}

get_config() {
  local key="$1"
  local default="${2:-}"
  if [[ -f "$CONFIG" ]] && command -v jq >/dev/null 2>&1; then
    jq -r "$key // empty" "$CONFIG" 2>/dev/null || echo "$default"
  else
    echo "$default"
  fi
}

play_sound() {
  local sound_path="$1"
  [[ -z "$sound_path" || "$sound_path" == "null" ]] && return 0
  [[ -f "$sound_path" ]] || return 0
  if command -v afplay >/dev/null 2>&1; then
    afplay "$sound_path" &
  fi
}

escape_applescript() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

notify_macos() {
  local title="$1"
  local message="$2"
  local enabled activate_on_click bundle_id group_id
  enabled="$(get_config '.notifications.enabled' 'true')"
  [[ "$enabled" != "true" ]] && return 0

  activate_on_click="$(get_config '.notifications.activate_on_click' 'true')"
  bundle_id="$(get_config '.notifications.app_bundle_id' 'com.todesktop.230313mzl4w4u92')"
  group_id="$(get_config '.notifications.group_id' 'cursor-agent')"

  if command -v terminal-notifier >/dev/null 2>&1; then
    local -a tn_args=(-title "$title" -message "$message")
    [[ -n "$group_id" && "$group_id" != "null" ]] && tn_args+=(-group "$group_id")
    if [[ "$activate_on_click" == "true" ]]; then
      tn_args+=(-activate "$bundle_id")
    else
      tn_args+=(-sender "$bundle_id")
    fi
    terminal-notifier "${tn_args[@]}" >/dev/null 2>&1 &
    return 0
  fi

  if command -v osascript >/dev/null 2>&1; then
    local safe_title safe_message
    safe_title="$(escape_applescript "$title")"
    safe_message="$(escape_applescript "$message")"
    osascript -e "display notification \"$safe_message\" with title \"$safe_title\"" >/dev/null 2>&1 || true
  fi
}

notify_state() {
  local state="$1"
  local sound_key="$2"
  local message_key="$3"
  local custom_message="${4:-}"
  local sound
  local message
  sound="$(get_config ".sounds.$sound_key" "")"
  if [[ -n "$custom_message" ]]; then
    message="$custom_message"
  else
    message="$(get_config ".notifications.messages.$message_key" "Cursor agent update")"
  fi
  play_sound "$sound"
  notify_macos "Cursor" "$message"
}

should_notify() {
  local cooldown
  cooldown="$(get_config '.behavior.notify_cooldown_seconds' '3')"
  local stamp_file="/tmp/cursor-agent-notify.last"
  local now last
  now="$(date +%s)"
  last=0
  [[ -f "$stamp_file" ]] && last="$(cat "$stamp_file" 2>/dev/null || echo 0)"
  if (( now - last < cooldown )); then
    return 1
  fi
  echo "$now" > "$stamp_file"
  return 0
}

notify_approval() {
  local detail="$1"
  if ! should_notify; then
    return 0
  fi
  local template
  template="$(get_config '.notifications.messages.approval_needed' '需要你的批准才能继续')"
  if [[ -n "$detail" ]]; then
    notify_state "approval" "approval_needed" "approval_needed" "${template} — ${detail}"
  else
    notify_state "approval" "approval_needed" "approval_needed"
  fi
}

INPUT="$(read_input)"
EVENT="$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null || true)"

case "$EVENT" in
  stop)
    if [[ "$(get_config '.behavior.play_on_stop' 'true')" != "true" ]]; then
      echo '{}'
      exit 0
    fi
    STATUS="$(echo "$INPUT" | jq -r '.status // "completed"' 2>/dev/null || echo "completed")"
    case "$STATUS" in
      completed)
        notify_state "complete" "agent_turn_complete" "agent_turn_complete"
        ;;
      error|aborted)
        notify_state "error" "agent_error" "agent_error"
        ;;
    esac
    echo '{}'
    ;;

  subagentStop)
    if [[ "$(get_config '.behavior.play_on_subagent_stop' 'true')" == "true" ]]; then
      notify_state "subagent" "subagent_complete" "subagent_complete"
    fi
    echo '{}'
    ;;

  sessionStart)
    if [[ "$(get_config '.behavior.play_on_session_start' 'false')" == "true" ]]; then
      notify_state "start" "session_start" "agent_turn_complete"
    fi
    echo '{}'
    ;;

  preToolUse)
    if [[ "$(get_config '.behavior.notify_on_tool_approval' 'true')" == "true" ]]; then
      TOOL="$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)"
      DETAIL=""
      case "$TOOL" in
        Write|StrReplace|Delete|EditNotebook|ApplyPatch)
          DETAIL="$TOOL"
          ;;
        Task)
          DETAIL="Subagent task"
          ;;
      esac
      if [[ -n "$DETAIL" ]]; then
        notify_approval "$DETAIL"
      fi
    fi
    echo '{"permission":"allow"}'
    ;;

  beforeShellExecution)
    COMMAND="$(echo "$INPUT" | jq -r '.command // empty' 2>/dev/null || true)"
    if [[ "$(get_config '.behavior.notify_on_tool_approval' 'true')" == "true" ]]; then
      SHORT_CMD="$COMMAND"
      [[ ${#SHORT_CMD} -gt 72 ]] && SHORT_CMD="${SHORT_CMD:0:72}…"
      notify_approval "$SHORT_CMD"
    elif [[ "$(get_config '.behavior.notify_on_shell_approval' 'false')" == "true" ]] && [[ -f "$CONFIG" ]]; then
      NEEDS_ASK=false
      while IFS= read -r pattern; do
        [[ -z "$pattern" ]] && continue
        if echo "$COMMAND" | grep -qE "$pattern"; then
          NEEDS_ASK=true
          break
        fi
      done < <(jq -r '.behavior.shell_approval_patterns[]? // empty' "$CONFIG" 2>/dev/null)
      if [[ "$NEEDS_ASK" == "true" ]]; then
        notify_approval "$COMMAND"
        jq -n \
          --arg cmd "$COMMAND" \
          '{
            permission: "ask",
            user_message: ("Shell command needs your approval: " + $cmd)
          }'
        exit 0
      fi
    fi
    echo '{"permission":"allow"}'
    ;;

  beforeMCPExecution)
    if [[ "$(get_config '.behavior.notify_on_tool_approval' 'true')" == "true" ]]; then
      MCP_TOOL="$(echo "$INPUT" | jq -r '.tool_name // "MCP tool"' 2>/dev/null || echo "MCP tool")"
      notify_approval "$MCP_TOOL"
    fi
    echo '{"permission":"allow"}'
    ;;

  *)
    echo '{}'
    ;;
esac

exit 0
