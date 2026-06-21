# AGENTS.md

## Mission

StretchBlocker is a personal macOS stretch-reminder app. It shows strong, safe interruption overlays. It must never pretend to be an unbreakable kiosk/security product.

## Stack

- Swift 6 language mode.
- SwiftUI for app/menu/settings.
- AppKit for overlay windows.
- Xcode project generated from `project.yml`.
- Core scheduling logic lives outside UI code.

## Commands

- Bootstrap: `scripts/bootstrap.sh`
- Generate Xcode project: `xcodegen generate`
- Format: `scripts/format.sh`
- Verify all: `scripts/verify.sh`

## Non-negotiables

- Do not hand-edit `.xcodeproj` or `.pbxproj`.
- Run `xcodegen generate` after changing `project.yml`.
- Run `scripts/verify.sh` before claiming done.
- Do not add Accessibility or Input Monitoring permissions unless an ADR explains why.
- Do not add network entitlement unless update/sync behavior exists and an ADR explains it.
- Overlay code must handle all screens using `NSScreen.screens`.
- Overlay must preserve an obvious emergency escape path.
- Timer/scheduling rules belong in `Sources/Core`, not SwiftUI views.
- No private macOS APIs.

## Done Means

- Build passes.
- SwiftFormat passes.
- SwiftLint passes.
- Tests pass.
- Changed behavior has Swift Testing coverage or documented manual test.
- Entitlement, permission, signing, or update changes have an ADR.
