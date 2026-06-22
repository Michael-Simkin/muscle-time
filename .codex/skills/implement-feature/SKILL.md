---
name: implement-feature
description: Implement a focused Muscle Time feature safely.
paths:
  - "Sources/**/*.swift"
  - "Tests/**/*.swift"
  - "project.yml"
---

# Implement Feature

1. Read `AGENTS.md`.
2. Identify owning module:
   - scheduling/settings: `Sources/Core`
   - menu/settings UI: `Sources/App`
   - screen blocking: `Sources/Overlay`
3. Make smallest coherent diff.
4. Add or update tests.
5. Run:
   - `scripts/format.sh`
   - `scripts/verify.sh`
6. Report:
   - files changed
   - tests added
   - verify result
   - unresolved risk, if any

# Hard Rules

- No private macOS APIs.
- No new entitlement without ADR.
- No single-screen overlay logic.
- No direct `UserDefaults.standard` outside SettingsStore.
