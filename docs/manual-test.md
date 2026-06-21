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
- Sleep/wake: next break schedule remains sane.

## Escape

- Skip button works.
- Emergency Quit works.
- Menu bar quit works after overlay dismissed.

## Settings

- Interval persists after restart.
- Launch at login toggle persists.
- Invalid intervals rejected.
