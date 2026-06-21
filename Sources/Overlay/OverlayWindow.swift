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
}
