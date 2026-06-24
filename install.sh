#!/usr/bin/env bash
# Install cursor-agent-notify into ~/.cursor (user-level hooks).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CURSOR_DIR="${CURSOR_DIR:-$HOME/.cursor}"
HOOKS_DIR="$CURSOR_DIR/hooks"
SKILL_DIR="$CURSOR_DIR/skills/cursor-agent-notify"

echo "→ Installing cursor-agent-notify to $CURSOR_DIR"

mkdir -p "$HOOKS_DIR" "$SKILL_DIR"

install -m 755 "$ROOT/scripts/agent-notify.sh" "$HOOKS_DIR/agent-notify.sh"

if [[ -f "$HOOKS_DIR/notify-config.json" ]]; then
  echo "  • notify-config.json exists — kept (see notify-config.example.json for new keys)"
else
  cp "$ROOT/notify-config.example.json" "$HOOKS_DIR/notify-config.json"
  echo "  • Created $HOOKS_DIR/notify-config.json"
fi

HOOKS_JSON="$CURSOR_DIR/hooks.json"
if [[ -f "$HOOKS_JSON" ]]; then
  backup="$HOOKS_JSON.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$HOOKS_JSON" "$backup"
  echo "  • Backed up existing hooks.json → $backup"
  if command -v jq >/dev/null 2>&1; then
    jq -s '
      .[0] as $existing |
      .[1] as $new |
      $existing * {
        version: ($existing.version // $new.version // 1),
        hooks: (($existing.hooks // {}) * ($new.hooks // {}))
      }
    ' "$HOOKS_JSON" "$ROOT/hooks.json.example" > "$HOOKS_JSON.tmp"
    mv "$HOOKS_JSON.tmp" "$HOOKS_JSON"
    echo "  • Merged hooks into $HOOKS_JSON"
  else
    echo "  ⚠ jq not found — copying hooks.json.example (manual merge may be needed)"
    cp "$ROOT/hooks.json.example" "$HOOKS_JSON"
  fi
else
  cp "$ROOT/hooks.json.example" "$HOOKS_JSON"
  echo "  • Created $HOOKS_JSON"
fi

cp "$ROOT/skill/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$ROOT/docs/reference.md" "$SKILL_DIR/reference.md"
cp "$ROOT/notify-config.example.json" "$SKILL_DIR/notify-config.example.json"

echo ""
echo "Done. Next steps:"
echo "  1. brew install jq terminal-notifier   # if not installed"
echo "  2. System Settings → Notifications → terminal-notifier → Allow"
echo "  3. Restart Cursor (or save hooks.json to reload)"
echo "  4. First run: click Allow hooks/ in Cursor when prompted"
echo ""
echo "Test:"
echo "  $ROOT/bin/test.sh complete"
echo "  $ROOT/bin/test.sh approval"
