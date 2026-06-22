# Muscle Time

Muscle Time is a local macOS menu bar app for recurring muscle breaks. The break screen says
`Muscle Time!`, plays a selected bundled voice, and gives an obvious escape path.

This is not kiosk or security software. It uses public macOS APIs for strong, best-effort
interruption overlays.

## Requirements

- macOS 15.0 or newer.
- Xcode installed.
- Xcode command line tools selected with `xcode-select`.
- Homebrew for installing project tools.

## Install From Source

Clone the repo, install tools, and generate the Xcode project:

```sh
git clone <repo-url>
cd muscle-time
scripts/bootstrap.sh
```

Build the app:

```sh
scripts/build.sh
```

Run it from the build output:

```sh
open .build/DerivedData/Build/Products/Debug/MuscleTime.app
```

For normal local use, copy the built app into Applications:

```sh
cp -R .build/DerivedData/Build/Products/Debug/MuscleTime.app /Applications/
open /Applications/MuscleTime.app
```

## First Launch

- macOS asks for notification permission. Allow it to receive the 5-minute warning.
- The menu bar shows the flex-arm icon and remaining time.
- Open settings from the menu bar item to configure the cycle length and voice.

## Configuration

- Cycle length uses strict `HH:MM` input.
- Allowed range is `00:10` through `12:00`.
- Applying a new cycle length resets the countdown from the apply time.
- Voice options are bundled in the app and selected from the settings picker.

## Break Behavior

- A notification is scheduled 5 minutes before each normal break.
- At break time, an overlay appears on every connected display.
- The overlay stays visible for 10 seconds, then fades out and starts the next cycle.
- `Done` fades the overlay immediately and starts the next cycle.
- `Postpone 5 min` fades the overlay and schedules the next break 5 minutes out.
- Sleep/wake and quit/reopen reset the timer from the current time.

## Development

Regenerate the Xcode project after changing `project.yml`:

```sh
xcodegen generate
```

Run the full local verification before claiming a change is done:

```sh
scripts/verify.sh
```

Useful project commands:

```sh
scripts/format.sh
scripts/lint.sh
scripts/analyze.sh
scripts/build.sh
```

The same commands are exposed through `mise` tasks:

```sh
mise run bootstrap
mise run verify
```

## Troubleshooting

- If `xcodegen`, `swiftformat`, `swiftlint`, or `xcbeautify` is missing, run `brew bundle`.
- If the Xcode project is stale, run `xcodegen generate`.
- If notifications do not appear, check macOS System Settings → Notifications → Muscle Time.
- If the overlay does not cover lock screen, secure prompts, or some full-screen system UI, that is expected. The app intentionally avoids private APIs and invasive permissions.
