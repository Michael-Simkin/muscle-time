import AppKit

// swiftlint:disable:next unused_import
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = MuscleTimeTimerModel()

    private let logger = Logger(subsystem: "com.michael.MuscleTime", category: "App")
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        statusItemController = StatusItemController(model: model)

        logger.notice(
            """
            Muscle Time app initialized. bundleID=\(Bundle.main.bundleIdentifier ?? "missing", privacy: .public) \
            bundlePath=\(Bundle.main.bundlePath, privacy: .public)
            """,
        )
    }
}
