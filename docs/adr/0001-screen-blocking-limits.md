# ADR 0001: Screen Blocking Limits

## Decision

Muscle Time uses public AppKit window APIs to create strong interruption overlays. It does not claim unbreakable kiosk/security behavior.

## Reason

macOS does not guarantee normal apps can cover all system UI, full-screen Spaces, secure contexts, or lock screen.

## Consequences

- Overlay is best-effort.
- Manual testing covers full-screen apps, Spaces, and multiple displays.
- App preserves emergency escape.
- No private APIs.
