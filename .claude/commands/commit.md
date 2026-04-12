Run `git diff --staged` to see what's staged. Then write and execute a conventional commit.

Format: `<type>(<scope>): <description>`

Types: feat / fix / refactor / test / chore / docs / style / perf

Rules:
- Subject line under 72 chars, lowercase, no trailing period
- Scope = the module, app, or area changed (e.g. `auth`, `api`, `models`)
- Add a body only if the *why* isn't obvious from the subject
- If nothing is staged, say so and stop — do not stage files automatically

After writing the message, run the commit.
