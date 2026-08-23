#!/usr/bin/env bash
# Claude Code generator
# Usage: generate.sh <target_dir> [--symlink]

set -e

TARGET_DIR="${1:-.}"
USE_SYMLINK=false
if [[ "$2" == "--symlink" || "$3" == "--symlink" ]]; then
  USE_SYMLINK=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "==> Configuring Claude Code in ${TARGET_DIR}..."

# Create directories
mkdir -p "${TARGET_DIR}/.claude/commands"
mkdir -p "${TARGET_DIR}/scripts"

# Copy / Symlink commands
for cmd_file in "${REPO_ROOT}/src/commands"/*.md; do
  cmd_name="$(basename "$cmd_file")"
  if [ "$USE_SYMLINK" = true ]; then
    ln -sf "${cmd_file}" "${TARGET_DIR}/.claude/commands/${cmd_name}"
  else
    cp "${cmd_file}" "${TARGET_DIR}/.claude/commands/${cmd_name}"
  fi
done

# Copy / Symlink scripts
for script_file in "${REPO_ROOT}/scripts"/*.sh; do
  script_name="$(basename "$script_file")"
  if [ "$USE_SYMLINK" = true ]; then
    ln -sf "${script_file}" "${TARGET_DIR}/scripts/${script_name}"
  else
    cp "${script_file}" "${TARGET_DIR}/scripts/${script_name}"
  fi
  chmod +x "${TARGET_DIR}/scripts/${script_name}" 2>/dev/null || true
done

# Generate .claude/settings.json or hooks configuration
SETTINGS_FILE="${TARGET_DIR}/.claude/settings.json"
cat > "${SETTINGS_FILE}" << 'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/lint-python.sh"
          },
          {
            "type": "command",
            "command": "./scripts/format-js.sh"
          },
          {
            "type": "command",
            "command": "./scripts/format-go.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/guard-destructive.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/notify.sh \"Claude Code\" \"Claude finished responding\" \"Glass\""
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/notify.sh \"Claude Code\" \"Subagent finished\" \"Tink\""
          }
        ]
      }
    ]
  }
}
EOF

echo "✓ Claude Code configured successfully."
