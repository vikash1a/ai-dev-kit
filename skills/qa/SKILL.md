---
name: qa
description: Generates a comprehensive QA testing checklist covering happy paths, permissions, validations, edge cases, and regression risks.
---

Generate a QA checklist for the feature, endpoint, or component described below.

Target: $ARGUMENTS

---

## Happy Path
- Core flow works end-to-end
- Expected response codes, output shapes, and side effects

## Access & Permission Boundaries
- Unauthenticated / unauthorised requests are rejected correctly
- Users can only access resources they own or are permitted to access

## Input Validation
- Required fields missing → clear error
- Fields at max length, min length, and just over
- Invalid types and formats
- Null / empty / whitespace-only values

## Edge Cases
- Empty results / no data
- Duplicate or repeated submissions
- Concurrent writes to the same resource
- Pagination: first page, last page, out-of-range page

## Error Handling
- Errors don't leak internal details (stack traces, IDs, DB structure)
- Error messages are user-facing, not developer-facing

## Regression Risks
What existing behaviour could break as a side effect of this change.
