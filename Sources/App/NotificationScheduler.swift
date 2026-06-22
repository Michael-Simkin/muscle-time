import Foundation

// swiftlint:disable:next unused_import
import OSLog
import UserNotifications

final class NotificationScheduler: NSObject, UNUserNotificationCenterDelegate {
    private static let notificationIdentifier = "muscle-time-upcoming-break"
    private static let notificationLeadTime: TimeInterval = 300

    private let logger = Logger(subsystem: "com.michael.MuscleTime", category: "Notifications")

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        logger.info("Notification scheduler initialized and delegate assigned.")
    }

    func requestAuthorization() {
        let logger = logger

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let statusDescription = Self.description(for: settings.authorizationStatus)
            logger.info(
                "Notification authorization before request: \(statusDescription, privacy: .public)",
            )
        }

        logger.info("Requesting notification authorization.")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                logger.error("Notification permission request failed: \(error.localizedDescription, privacy: .public)")
                return
            }

            logger.info("Notification authorization request completed. granted=\(granted, privacy: .public)")
        }
    }

    func schedulePreBreakNotification(before breakDate: Date) {
        let notificationDate = breakDate.addingTimeInterval(-Self.notificationLeadTime)
        let timeInterval = notificationDate.timeIntervalSinceNow

        cancelPreBreakNotification()

        guard timeInterval > 1 else {
            logger.info(
                "Skipping pre-break notification. timeInterval=\(timeInterval, privacy: .public)",
            )
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Muscle Time soon"
        content.body = "5 minutes until Muscle Time."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: trigger,
        )
        let logger = logger
        logger.info(
            """
            Scheduling pre-break notification. breakDate=\(breakDate.description, privacy: .public) \
            notificationDate=\(notificationDate.description, privacy: .public) \
            timeInterval=\(timeInterval, privacy: .public)
            """,
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Scheduling notification failed: \(error.localizedDescription, privacy: .public)")
                return
            }

            logger.info("Pre-break notification scheduled.")
        }
    }

    func cancelPreBreakNotification() {
        logger.info("Canceling pending pre-break notification if present.")
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
    }

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
    ) async -> UNNotificationPresentationOptions {
        logger.info("Presenting notification while app is active.")
        return [.banner, .sound]
    }

    nonisolated static func description(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            "notDetermined"
        case .denied:
            "denied"
        case .authorized:
            "authorized"
        case .provisional:
            "provisional"
        case .ephemeral:
            "ephemeral"
        @unknown default:
            "unknown"
        }
    }
}
