# Manual Test Checklist

## Menu Bar & Logo

- Menu bar icon shows a flexed-arm silhouette and adapts to light/dark menu bar.
- App icon (Finder/Dock) shows the flexed-arm silhouette on the gradient background.
- Popover shows a progress ring at the top, above the settings.
- Ring fills clockwise as the next break approaches and shows the countdown inside.
- Ring shows `Now` / `Muscle Time!` while a break is active.

## Overlay

- Overlay shows a spin wheel (Push-ups / Pull-ups / Plank / Treadmill) in a styled card with Done/Postpone.
- Done is disabled until the wheel has been spun; Postpone (Esc) stays enabled as the escape path.
- Tapping "Spin the wheel" spins the wheel and it visibly lands with the top pointer on the announced exercise.
- The subtitle updates to the chosen exercise after the spin; "Spin again" re-spins.
- When the wheel lands, a success chime plays and a voice announces the chosen exercise.
- Clicking Done plays the completion flourish, which finishes even as the overlay fades out.
- Single monitor: overlay covers full screen.
- Multiple monitors: overlay appears on every screen.
- External monitor attach while idle: next break covers new screen.
- External monitor attach during break: overlay rebuilds.
- Full-screen Safari: overlay behavior recorded.
- Full-screen video player: overlay behavior recorded.
- Mission Control: escape behavior remains possible.
- Lock screen: app does not crash or spin.
- Sleep/wake: countdown resets from the wake time.

## Escape

- Done button fades overlay and starts the next cycle.
- Postpone 5 min button fades overlay and schedules the next break 5 minutes out.
- Auto fade after 10 seconds starts the next cycle.
- Emergency Quit works.
- Menu bar quit works after overlay dismissed.

## Settings

- Cycle length accepts valid `HH:MM` values from `00:10` through `12:00`.
- Invalid cycle lengths disable Apply.
- Applying cycle length resets the countdown from the apply time.
- Voice picker is a dropdown; selecting a voice plays a preview and persists after restart.
- All voices (Xavier, Guy, Aviv) load and play without error.

## Notifications

- Notification permission is requested on launch.
- A notification appears 5 minutes before a normal cycle break.
- Postponed breaks do not trigger an immediate 5-minute warning.
