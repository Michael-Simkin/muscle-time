import AppKit

@MainActor
final class OverlayWindow: NSWindow {
    init(screen: NSScreen, contentView: NSView) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
        )

        self.contentView = contentView
        alphaValue = 1
        backgroundColor = .clear
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hasShadow = false
        ignoresMouseEvents = false
        isMovable = false
        isOpaque = false
        level = .screenSaver
        isReleasedWhenClosed = false
        setFrame(screen.frame, display: true)
    }

    /// Borderless windows cannot become key by default, which would disable the
    /// overlay's keyboard shortcuts (Return to finish, Escape to postpone).
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}
