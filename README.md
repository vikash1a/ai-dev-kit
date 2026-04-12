# claude-dev-kit

Personal Claude Code plugin — slash commands and hooks for everyday dev work.

## Commands

| Command | What it does |
|---|---|
| `/commit` | Reads staged diff, writes a conventional commit message, and runs the commit |
| `/review [file or diff]` | Code review: correctness, security, readability, test coverage |
| `/spec <feature>` | Turns a feature description into a plan: context, acceptance criteria, tasks, risks |
| `/qa <target>` | QA checklist: happy path, access boundaries, input validation, edge cases, regressions |

## Hooks

| Event | What it does |
|---|---|
| `PostToolUse` (Write/Edit) | Runs `ruff check --fix` on any `.py` file after it's written or edited |
| `Stop` | Sends a macOS desktop notification when Claude finishes responding |

## Installation

### As a plugin (recommended)

```bash
claude plugin marketplace add vikash1a/claude-dev-kit
claude plugin install claude-dev-kit@claude-dev-kit
```

### Requirements

- `ruff` must be installed for the PostToolUse hook (`pip install ruff` or `brew install ruff`)
- macOS required for the Stop notification hook
