#!/usr/bin/env bash
# Provider-agnostic Go formatter hook (gofmt / goimports)
# Accepts file as argument ($1) or extracts from stdin JSON payload (Claude Code / Antigravity AGY)

FILE="$1"

if [ -z "$FILE" ] && [ ! -t 0 ]; then
  FILE=$(python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = data.get('tool_input', {}).get('file_path') or data.get('tool_input', {}).get('path') or data.get('tool_input', {}).get('TargetFile')
    if not path and 'toolCall' in data:
        args = data.get('toolCall', {}).get('args', {})
        path = args.get('TargetFile') or args.get('file_path') or args.get('path') or args.get('AbsolutePath')
    if not path:
        path = data.get('file_path') or data.get('TargetFile') or data.get('path')
    print(path or '')
except Exception:
    print('')
" 2>/dev/null)
fi

if [ -n "$FILE" ] && [[ "$FILE" == *.go ]] && [ -f "$FILE" ]; then
  if command -v goimports &>/dev/null; then
    goimports -w "$FILE" 2>/dev/null
  elif command -v gofmt &>/dev/null; then
    gofmt -w "$FILE" 2>/dev/null
  fi
fi

exit 0
