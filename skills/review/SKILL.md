---
name: review
description: Review code or diff across multiple dimensions including correctness, security, readability, and test coverage.
---

Review the code specified in $ARGUMENTS (or the current diff if no argument given).

## Correctness
- Does the logic do what it claims? Are there off-by-one errors, wrong conditions, or missed cases?
- Are return values and error states handled everywhere they're used?

## Security
- Is any user input reaching the DB, filesystem, or shell without validation or sanitisation?
- Are secrets, tokens, or PII handled safely — not logged, not leaked in responses?
- Are access checks enforced at the right layer, not just the UI?

## Readability & Maintainability
- Is the code doing one thing per function/class?
- Are names clear enough that a comment isn't needed?
- Is there dead code, unused imports, or commented-out blocks?

## Test Coverage
- Are the happy path and the main failure modes tested?
- Are edge cases (empty input, nulls, boundary values) covered?

Report findings grouped by severity: **Critical / High / Medium / Low**. For each finding include the file:line and a one-line fix recommendation.
