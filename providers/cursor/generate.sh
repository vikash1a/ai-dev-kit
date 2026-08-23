#!/usr/bin/env bash
# Cursor IDE generator
# Usage: generate.sh <target_dir> [--symlink]

set -e

TARGET_DIR="${1:-.}"
USE_SYMLINK=false
if [[ "$2" == "--symlink" || "$3" == "--symlink" ]]; then
  USE_SYMLINK=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "==> Configuring Cursor IDE in ${TARGET_DIR}..."

# Create directories
mkdir -p "${TARGET_DIR}/.cursor/commands"
mkdir -p "${TARGET_DIR}/.cursor/rules"
mkdir -p "${TARGET_DIR}/scripts"

# Copy / Symlink commands
for cmd_file in "${REPO_ROOT}/src/commands"/*.md; do
  cmd_name="$(basename "$cmd_file")"
  if [ "$USE_SYMLINK" = true ]; then
    ln -sf "${cmd_file}" "${TARGET_DIR}/.cursor/commands/${cmd_name}"
  else
    cp "${cmd_file}" "${TARGET_DIR}/.cursor/commands/${cmd_name}"
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

# Generate .cursor/rules/dev-kit.mdc from src/rules/dev-kit.md
RULE_SRC="${REPO_ROOT}/src/rules/dev-kit.md"
RULE_DEST="${TARGET_DIR}/.cursor/rules/dev-kit.mdc"

cat > "${RULE_DEST}" << 'EOF'
---
description: AI Dev Kit - Coding standards, linting, formatting, and safety guardrails
globs: *
alwaysApply: true
---

EOF

if [ -f "$RULE_SRC" ]; then
  cat "$RULE_SRC" >> "${RULE_DEST}"
fi

cat >> "${RULE_DEST}" << 'EOF'

## Post-Edit Verification (Cursor)
- After modifying Python files, run `ruff check --fix` and `ruff format` (or `./scripts/lint-python.sh <file>`).
- After modifying JS/TS/JSON/CSS files, run `prettier --write` (or `./scripts/format-js.sh <file>`).
- After modifying Go files, run `gofmt -w` (or `./scripts/format-go.sh <file>`).
EOF

echo "✓ Cursor IDE configured successfully."
