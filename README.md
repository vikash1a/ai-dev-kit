# claude-config

Personal Claude Code configuration — slash commands, hooks, and settings.

## Slash Commands

Stored in `.claude/commands/`. Available in any project that includes this config.

| Command | What it does |
|---|---|
| `/commit` | Reads staged diff, writes a conventional commit message, and runs the commit |
| `/review [file or diff]` | Code review checklist: correctness, security, readability, test coverage |
| `/spec <feature description>` | Turns a feature description into a structured plan: context, acceptance criteria, tasks, risks |
| `/qa <target>` | Generates a QA checklist: happy path, access boundaries, input validation, edge cases, regressions |

## Hooks

Configured in `.claude/settings.json`.

| Event | What it does |
|---|---|
| `PostToolUse` (Write/Edit) | Runs `ruff check --fix` on any `.py` file after it's written or edited |
| `Stop` | Sends a macOS desktop notification when Claude finishes responding |

## Usage

To use these globally, symlink the commands directory:

```bash
ln -s ~/git-repos/claude-config/.claude/commands ~/.claude/commands
```

Or add this repo's `.claude/` path to `additionalDirectories` in `~/.claude/settings.json`.
