#!/usr/bin/env bash
# Cross-platform desktop notification script
# Usage: notify.sh [title] [message] [sound_name]

TITLE="${1:-AI Dev Kit}"
MESSAGE="${2:-Task completed}"
SOUND="${3:-Glass}"

# Read from stdin if piped (e.g. hook payload)
if [ ! -t 0 ]; then
  # Consume stdin so upstream doesn't break
  PAYLOAD=$(cat 2>/dev/null)
fi

# macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  if command -v osascript &>/dev/null; then
    osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\"" 2>/dev/null
  fi
  if command -v afplay &>/dev/null; then
    SOUND_PATH="/System/Library/Sounds/${SOUND}.aiff"
    if [ -f "$SOUND_PATH" ]; then
      afplay "$SOUND_PATH" 2>/dev/null &
    else
      afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
    fi
  fi

# Linux
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v notify-send &>/dev/null; then
    notify-send "$TITLE" "$MESSAGE" 2>/dev/null
  fi
  if command -v paplay &>/dev/null; then
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
  elif command -v aplay &>/dev/null; then
    aplay /usr/share/sounds/sound-icons/prompt.wav 2>/dev/null &
  fi

# Windows / MINGW / MSYS / Cygwin
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32"* ]]; then
  if command -v powershell.exe &>/dev/null; then
    powershell.exe -Command "[reflection.assembly]::loadwithpartialname('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('${MESSAGE}', '${TITLE}')" 2>/dev/null &
  fi
fi

# Clean exit for hook contracts
exit 0
