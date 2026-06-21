import AppKit

@MainActor
final class ScreenObserver: NSObject {
    private let onChange: @MainActor () -> Void

    init(onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil,
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screensChanged() {
        onChange()
    }
}
