---
name: refactor-safely
description: Refactor without changing behavior.
model: claude-opus-4-8
effort: xhigh
paths:
  - "Sources/**/*.swift"
  - "Tests/**/*.swift"
---

# Refactor Safely

1. State behavior that must remain identical.
2. Add characterization test first if behavior is uncovered.
3. Refactor in small steps.
4. Keep public types minimal.
5. Run `scripts/verify.sh`.

# Forbidden

- No new feature behavior.
- No entitlement changes.
- No signing changes.
- No generated project edits.
