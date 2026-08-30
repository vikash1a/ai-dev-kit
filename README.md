# ai-dev-kit

Universal, declarative AI developer toolkit plugin for **Antigravity (AGY)**, **Claude Code**, and **Cursor**.

Zero build scripts, zero dependencies — pure declarative JSON and Markdown.

---

## 📁 Repository Structure

```text
ai-dev-kit/
├── plugin.json                 # Universal package manifest
├── mcp_config.json             # MCP server integrations (filesystem, github, notion, etc.)
├── hooks.json                  # Automated lifecycle hooks (macOS native)
├── rules/
│   └── dev-kit.md              # Coding standards & safety guardrails
├── agents/                     # Specialized subagent definitions
│   └── security-auditor.md     # AppSec vulnerability & security scanner
├── skills/                     # Specialized skills & playbooks
│   ├── commit/SKILL.md         # /commit (reads staged diff & conventional commit)
│   ├── review/SKILL.md         # /review (multi-dimension code review)
│   ├── spec/SKILL.md           # /spec (feature spec & implementation plan)
│   └── qa/SKILL.md             # /qa (QA checklist & edge cases)
└── README.md
```

---

## ⚡ Features

### 1. Skills & Playbooks
- **`/commit`**: Inspects staged changes, generates a concise conventional commit message, and commits.
- **`/review`**: Analyzes code/diff across correctness, security, maintainability, and test coverage.
- **`/spec <feature>`**: Generates structured feature implementation plans with tasks and risks.
- **`/qa <target>`**: Generates exhaustive QA test matrices covering validation, permissions, and edge cases.

### 2. Specialized Subagents (`agents/`)
- **`security-auditor`**: Dedicated AppSec subagent for vulnerability assessments, secret detection, injection checks, and dependency audits.

### 3. Native macOS Lifecycle Hooks (`hooks.json`)
- **Python**: Auto-lints & formats with `ruff check --fix` and `ruff format`.
- **JS / TS / Web**: Auto-formats with `prettier --write`.
- **Go**: Auto-formats with `gofmt -w`.
- **Session End**: Native macOS banner notification (`osascript`) and audio chime (`afplay Glass`).

### 4. Model Context Protocol (MCP) Servers (`mcp_config.json`)
- **Filesystem**: `@modelcontextprotocol/server-filesystem`
- **GitHub**: `@modelcontextprotocol/server-github` (`GITHUB_PERSONAL_ACCESS_TOKEN`)
- **Notion**: `notion-mcp-server` (`NOTION_API_KEY`)
- **Fetch**: `mcp-server-fetch` (via `uvx`)
- **Atlassian**: `@modelcontextprotocol/server-atlassian` (`Jira` / `Confluence`)
- **Google Sheets**: `google-sheets-mcp` (`GOOGLE_ACCESS_TOKEN`)

---

## 🚀 Installation & Management

### 1. Antigravity (AGY)

#### Native CLI Commands (Recommended)
```bash
# Install the plugin locally into your profile
agy plugin install /Users/vikash.sinha/git-repos/dev-tools/ai-dev-kit

# List installed plugins & verify loaded components
agy plugin list

# Temporarily disable or re-enable the plugin
agy plugin disable ai-dev-kit
agy plugin enable ai-dev-kit

# Uninstall / purge plugin
agy plugin uninstall ai-dev-kit
```

#### Alternative: Global Registration via `plugins.json`
Add the repository directly to `~/.gemini/config/plugins.json`:
```json
{
  "entries": [
    { "path": "/Users/vikash.sinha/git-repos/dev-tools/ai-dev-kit" }
  ]
}
```

#### Alternative: Workspace-Level Symlink
```bash
mkdir -p .agents/plugins
ln -sf /Users/vikash.sinha/git-repos/dev-tools/ai-dev-kit .agents/plugins/ai-dev-kit
```

---

### 2. Claude Code
```bash
# Install as a local plugin directly
claude plugin install /Users/vikash.sinha/git-repos/dev-tools/ai-dev-kit
```

---

### 3. Cursor IDE

Because `ai-dev-kit` contains `plugin.json` at its root, Cursor natively recognizes it as an **Agent Plugin**.

#### Option A: Local Plugin Development / User Scope (Recommended)
Symlink into Cursor's local plugins directory:
```bash
mkdir -p ~/.cursor/plugins/local
ln -sf /Users/vikash.sinha/git-repos/dev-tools/ai-dev-kit ~/.cursor/plugins/local/ai-dev-kit
```

#### Option B: Sidebar UI
1. Open **Customize** in the Cursor sidebar.
2. Under Plugins, select **Install** and choose **Project** or **User** scope.

#### Option C: Workspace-Level Symlink
```bash
mkdir -p .cursor/plugins
ln -sf /Users/vikash.sinha/git-repos/dev-tools/ai-dev-kit .cursor/plugins/ai-dev-kit
```
