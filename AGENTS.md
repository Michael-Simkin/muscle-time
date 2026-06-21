# AGENTS.md

## Mission

StretchBlocker is a personal macOS stretch-reminder app. It shows strong, safe interruption overlays. It must never pretend to be an unbreakable kiosk/security product.

## Stack

- Swift 6 language mode.
- SwiftUI for app/menu/settings.
- AppKit for overlay windows.
- Xcode project generated from `project.yml`.
- Core scheduling logic lives outside UI code.

## Code Style

- Write the most maintainable code possible, prioritizing simplicity and readability over cleverness or visual neatness.
- Prefer obvious, self-explanatory code even when it is longer, more explicit, or more verbose.

## Commands

- Bootstrap: `scripts/bootstrap.sh`
- Generate Xcode project: `xcodegen generate`
- Format: `scripts/format.sh`
- Lint/policy checks: `scripts/lint.sh`
- Static analyzer: `scripts/analyze.sh`
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
- Core code must not import AppKit, SwiftUI, UserNotifications, or ServiceManagement.
- No private macOS APIs.
- Prefer `MainActor` isolation over `DispatchQueue.main.async`.
- Do not use `Task.detached` without explicit cancellation/ownership design.
- Use `Logger` from OSLog instead of `print`.

## Done Means

- Build passes.
- SwiftFormat passes.
- SwiftLint passes.
- ShellCheck passes.
- Xcode static analyzer passes.
- Generated Xcode files are current.
- Tests pass.
- Changed behavior has Swift Testing coverage or documented manual test.
- Entitlement, permission, signing, or update changes have an ADR.
