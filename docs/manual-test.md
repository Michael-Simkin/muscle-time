# Manual Test Checklist

## Overlay

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
- Voice picker persists after restart.

## Notifications

- Notification permission is requested on launch.
- A notification appears 5 minutes before a normal cycle break.
- Postponed breaks do not trigger an immediate 5-minute warning.
