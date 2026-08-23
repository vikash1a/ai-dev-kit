#!/usr/bin/env bash
# Provider-agnostic destructive command detector and guard
# Accepts command as argument ($1) or extracts from stdin JSON payload (Claude Code / Antigravity AGY)

CMD="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$CMD" ] && [ ! -t 0 ]; then
  CMD=$(python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    cmd = data.get('tool_input', {}).get('command') or data.get('tool_input', {}).get('cmd')
    if not cmd and 'toolCall' in data:
        args = data.get('toolCall', {}).get('args', {})
        cmd = args.get('CommandLine') or args.get('command') or args.get('cmd')
    if not cmd:
        cmd = data.get('command') or data.get('CommandLine')
    print(cmd or '')
except Exception:
    print('')
" 2>/dev/null)
fi

if [ -n "$CMD" ]; then
  if [[ "$CMD" == *"rm -rf"* || "$CMD" == *"git push --force"* || "$CMD" == *"git push -f"* || "$CMD" == *"DROP TABLE"* || "$CMD" == *"mkfs"* || "$CMD" == *"dd if="* ]]; then
    "${SCRIPT_DIR}/notify.sh" "Destructive Command Guard" "⚠️ Destructive command detected: ${CMD:0:60}" "Basso"
  fi
fi

exit 0
