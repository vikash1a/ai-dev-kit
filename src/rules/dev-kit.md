# AI Dev Kit Guidelines

## Development Workflow
- Follow conventional commits: `<type>(<scope>): <description>` (feat, fix, refactor, test, chore, docs, style, perf).
- Keep changes minimal, well-tested, and well-scoped.
- Always run appropriate linters and formatters before submitting or finalizing code changes.

## Quality & Formatting
- **Python**: Run `ruff check --fix` and `ruff format` on any modified Python files.
- **TypeScript / JavaScript**: Format code using `prettier` (`npx prettier --write`).
- **Go**: Ensure Go code is formatted with `gofmt -w` or `goimports -w`.

## Safety Guardrails
- Exercise extreme caution with destructive actions like `rm -rf`, forced git pushes (`git push --force`), dropping database tables, or modifying production credentials.
- Double-check targets and confirm before running commands that can cause irreversible data loss.
