---
name: release-check
description: Review signing, notarization, entitlements, and update flow.
paths:
  - "Config/**"
  - "project.yml"
  - ".github/workflows/**"
  - "docs/adr/**"
---

# Release Check

Review only. Do not run signing, notarization, secret, or upload commands.

Check:

- Hardened Runtime enabled for Release.
- Entitlements minimal.
- Sandbox still enabled.
- No PR workflow has signing secrets.
- Notarization workflow is manual and protected.
- Sparkle/network entitlement exists only if update feed exists.
