#!/usr/bin/env bash
# Antigravity (AGY) provider generator
# Usage: generate.sh <target_dir> [--symlink]

set -e

TARGET_DIR="${1:-.}"
USE_SYMLINK=false
if [[ "$2" == "--symlink" || "$3" == "--symlink" ]]; then
  USE_SYMLINK=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "==> Configuring Antigravity (AGY) in ${TARGET_DIR}..."

# Create directories
mkdir -p "${TARGET_DIR}/.agents/skills"
mkdir -p "${TARGET_DIR}/.agents/rules"
mkdir -p "${TARGET_DIR}/.agents/plugins/ai-dev-kit"
mkdir -p "${TARGET_DIR}/scripts"

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

# Description resolver for portability (Bash 3.2+ compatible)
get_skill_desc() {
  case "$1" in
    commit) echo "Reads staged diff, writes a conventional commit message, and runs the commit." ;;
    review) echo "Review code or diff for correctness, security, readability, and test coverage." ;;
    spec)   echo "Turns a feature description into a structured implementation plan with acceptance criteria, tasks, and risks." ;;
    qa)     echo "Generates a comprehensive QA checklist for a feature, endpoint, or component." ;;
    *)      echo "AI Dev Kit procedure for $1" ;;
  esac
}

# Generate Skills from src/commands/*.md
for cmd_file in "${REPO_ROOT}/src/commands"/*.md; do
  cmd_basename="$(basename "$cmd_file" .md)"
  skill_dir="${TARGET_DIR}/.agents/skills/${cmd_basename}"
  mkdir -p "${skill_dir}"
  
  desc="$(get_skill_desc "$cmd_basename")"
  
  cat > "${skill_dir}/SKILL.md" << EOF
---
name: ${cmd_basename}
description: >-
  ${desc}
---

EOF
  cat "${cmd_file}" >> "${skill_dir}/SKILL.md"
done

# Copy rules to .agents/rules/
if [ -f "${REPO_ROOT}/src/rules/dev-kit.md" ]; then
  cp "${REPO_ROOT}/src/rules/dev-kit.md" "${TARGET_DIR}/.agents/rules/dev-kit.md"
fi

# Generate .agents/hooks.json
HOOKS_FILE="${TARGET_DIR}/.agents/hooks.json"
cat > "${HOOKS_FILE}" << 'EOF'
{
  "python-lint": {
    "PostToolUse": [
      {
        "matcher": "replace_file_content|write_to_file|multi_replace_file_content",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/lint-python.sh",
            "timeout": 30
          }
        ]
      }
    ]
  },
  "js-format": {
    "PostToolUse": [
      {
        "matcher": "replace_file_content|write_to_file|multi_replace_file_content",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/format-js.sh",
            "timeout": 30
          }
        ]
      }
    ]
  },
  "go-format": {
    "PostToolUse": [
      {
        "matcher": "replace_file_content|write_to_file|multi_replace_file_content",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/format-go.sh",
            "timeout": 30
          }
        ]
      }
    ]
  },
  "guard-destructive": {
    "PreToolUse": [
      {
        "matcher": "run_command",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/guard-destructive.sh",
            "timeout": 15
          }
        ]
      }
    ]
  },
  "desktop-notify": {
    "Stop": [
      {
        "type": "command",
        "command": "./scripts/notify.sh \"Antigravity\" \"Task finished\" \"Glass\"",
        "timeout": 10
      }
    ]
  }
}
EOF

# Generate plugin manifest
cat > "${TARGET_DIR}/.agents/plugins/ai-dev-kit/plugin.json" << 'EOF'
{
  "name": "ai-dev-kit",
  "description": "Universal AI dev toolkit: slash commands, skills, linting hooks, and desktop notifications"
}
EOF

echo "✓ Antigravity (AGY) configured successfully."
