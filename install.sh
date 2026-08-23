#!/usr/bin/env bash
# AI Dev Kit - Unified Multi-Provider Installer
# Sets up ai-dev-kit for Claude Code, Cursor, and Antigravity (AGY)

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="."
PROVIDERS=""
INSTALL_ALL=false
USE_SYMLINK=false

print_usage() {
  echo "Usage: ./install.sh [TARGET_DIR] [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --all                    Install support for all providers (Claude, Cursor, AGY)"
  echo "  --providers <list>       Comma-separated list of providers (e.g. --providers claude,cursor,agy)"
  echo "  --symlink                Use symlinks to source files instead of copying"
  echo "  -h, --help               Show this help message"
  echo ""
  echo "Examples:"
  echo "  ./install.sh --all"
  echo "  ./install.sh /path/to/project --all"
  echo "  ./install.sh --providers claude,cursor"
  echo "  ./install.sh --providers agy --symlink"
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      INSTALL_ALL=true
      shift
      ;;
    --providers)
      PROVIDERS="$2"
      shift 2
      ;;
    --symlink)
      USE_SYMLINK=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      if [[ -z "$TARGET_DIR" || "$TARGET_DIR" == "." ]]; then
        TARGET_DIR="$1"
      fi
      shift
      ;;
  esac
done

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"
mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                AI Dev Kit Installer (Universal)              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "Target directory: $TARGET_DIR"

# Ensure repo scripts are executable
chmod +x "${REPO_ROOT}/scripts"/*.sh 2>/dev/null || true
chmod +x "${REPO_ROOT}/providers"/*/*.sh 2>/dev/null || true

# Determine which providers to install
SELECTED_PROVIDERS=()

if [ "$INSTALL_ALL" = true ]; then
  SELECTED_PROVIDERS=("claude" "cursor" "agy")
elif [ -n "$PROVIDERS" ]; then
  IFS=',' read -ra ADDR <<< "$PROVIDERS"
  for p in "${ADDR[@]}"; do
    # Trim whitespace
    p_clean="$(echo "$p" | tr -d ' ' | tr '[:upper:]' '[:lower:]')"
    SELECTED_PROVIDERS+=("$p_clean")
  done
else
  # Auto-detection mode
  echo "Auto-detecting provider environments..."
  DETECTED=false
  
  if [ -d "${TARGET_DIR}/.claude" ] || command -v claude &>/dev/null; then
    SELECTED_PROVIDERS+=("claude")
    DETECTED=true
  fi
  
  if [ -d "${TARGET_DIR}/.cursor" ] || command -v cursor &>/dev/null; then
    SELECTED_PROVIDERS+=("cursor")
    DETECTED=true
  fi
  
  if [ -d "${TARGET_DIR}/.agents" ] || [ -d "${TARGET_DIR}/.gemini" ] || command -v agy &>/dev/null; then
    SELECTED_PROVIDERS+=("agy")
    DETECTED=true
  fi

  if [ "$DETECTED" = false ]; then
    echo "No existing provider folders detected. Defaulting to installing for ALL providers."
    SELECTED_PROVIDERS=("claude" "cursor" "agy")
  fi
fi

SYMLINK_FLAG=""
if [ "$USE_SYMLINK" = true ]; then
  SYMLINK_FLAG="--symlink"
fi

# Run generators for selected providers
for provider in "${SELECTED_PROVIDERS[@]}"; do
  case "$provider" in
    claude)
      "${REPO_ROOT}/providers/claude/generate.sh" "$TARGET_DIR" $SYMLINK_FLAG
      ;;
    cursor)
      "${REPO_ROOT}/providers/cursor/generate.sh" "$TARGET_DIR" $SYMLINK_FLAG
      ;;
    agy|antigravity)
      "${REPO_ROOT}/providers/agy/generate.sh" "$TARGET_DIR" $SYMLINK_FLAG
      ;;
    *)
      echo "⚠️  Unknown provider '$provider'. Skipping."
      ;;
  esac
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🎉 AI Dev Kit installation complete!"
echo "════════════════════════════════════════════════════════════════"
echo "Enabled features in $TARGET_DIR:"
echo " • Slash commands / Skills:  /commit, /review, /spec, /qa"
echo " • Automatic Linters:        ruff (Python), prettier (JS/TS), gofmt (Go)"
echo " • Safety Guardrails:        Destructive bash command alerts"
echo " • Desktop Notifications:    Mac / Linux / Windows completion sounds"
echo ""
