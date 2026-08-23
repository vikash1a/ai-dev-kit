# ai-dev-kit

Universal AI developer toolkit — slash commands, skills, automatic linting hooks, safety guardrails, and desktop notifications for **Claude Code**, **Cursor**, and **Antigravity (AGY)**.

---

## Features

### 1. Slash Commands & Skills

| Command / Skill | Description |
|---|---|
| `/commit` | Reads staged diff, generates a conventional commit message, and commits |
| `/review [file/diff]` | Multi-dimension code review: correctness, security, readability, test coverage |
| `/spec <feature>` | Generates structured implementation plan: context, acceptance criteria, tasks, risks |
| `/qa <target>` | Generates thorough QA checklist: happy path, permissions, validation, edge cases |

### 2. Automatic Hooks & Verification

| Event / Trigger | Action | Target / Providers |
|---|---|---|
| **Python edits** | Auto-lints & formats with `ruff check --fix` and `ruff format` | Claude Code, AGY, Cursor |
| **JS / TS edits** | Auto-formats with `prettier --write` | Claude Code, AGY, Cursor |
| **Go edits** | Auto-formats with `gofmt -w` / `goimports -w` | Claude Code, AGY, Cursor |
| **Destructive commands** | Detects `rm -rf`, `git push --force`, `DROP TABLE` + sounds alert | Claude Code, AGY |
| **Session completion** | Cross-platform desktop notification + completion sound | Claude Code, AGY |

---

## Compatibility Matrix

| Feature | Claude Code | Cursor IDE | Antigravity (AGY) |
|---|:---:|:---:|:---:|
| **Slash Commands / Skills** | `.claude/commands/*.md` | `.cursor/commands/*.md` | `.agents/skills/<name>/SKILL.md` |
| **Rules & Guardrails** | `.claude/settings.json` | `.cursor/rules/dev-kit.mdc` | `.agents/rules/dev-kit.md` |
| **Lifecycle Hooks** | Native JSON (`PostToolUse`, `Stop`) | Rule-instructed verification | Native JSON (`PostToolUse`, `PreToolUse`, `Stop`) |
| **Desktop Notifications** | macOS, Linux, Windows | Via scripts | macOS, Linux, Windows |

---

## Installation

### Method 1: Universal Installer (Recommended)

Run `install.sh` from the repository:

```bash
# Auto-detect tools in current project
./install.sh

# Install for all three providers in a target project
./install.sh /path/to/my-project --all

# Install for specific providers only
./install.sh /path/to/my-project --providers claude,cursor,agy

# Use symlinks instead of copying files
./install.sh /path/to/my-project --all --symlink
```

---

### Method 2: Provider-Specific Setup

#### Claude Code (Plugin Marketplace)
```bash
claude plugin marketplace add vikash1a/ai-dev-kit
claude plugin install ai-dev-kit@ai-dev-kit
```

#### Antigravity (AGY)
```bash
./providers/agy/generate.sh /path/to/my-project
```

#### Cursor IDE
```bash
./providers/cursor/generate.sh /path/to/my-project
```

---

## Requirements

- **Python linting**: `ruff` (`pip install ruff` or `brew install ruff`)
- **JS/TS formatting**: `prettier` (`npm install -g prettier` or local `node_modules`)
- **Go formatting**: `gofmt` or `goimports`
- **Notifications**:
  - macOS: built-in (`osascript`, `afplay`)
  - Linux: `notify-send`, `paplay` / `aplay`
  - Windows: PowerShell
