import Foundation

// swiftlint:disable:next unused_import
import OSLog
import UserNotifications

final class NotificationScheduler: NSObject, UNUserNotificationCenterDelegate {
    private static let notificationIdentifier = "muscle-time-upcoming-break"
    private static let notificationLeadTime: TimeInterval = 300

    private let logger = Logger(subsystem: "com.michael.StretchBlocker", category: "Notifications")

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        let logger = logger

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error {
                logger.error("Notification permission request failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func schedulePreBreakNotification(before breakDate: Date) {
        let notificationDate = breakDate.addingTimeInterval(-Self.notificationLeadTime)
        let timeInterval = notificationDate.timeIntervalSinceNow

        cancelPreBreakNotification()

        guard timeInterval > 1 else {
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

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Scheduling notification failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func cancelPreBreakNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
    }

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
