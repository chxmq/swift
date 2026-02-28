import SwiftUI
import UserNotifications

/// Manages local notification scheduling for alarms
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    /// Request notification permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, error in
            if error != nil {
                // Permission denied or error — user can enable in Settings
            }
        }
    }

    /// Schedule a notification for an alarm
    func schedule(_ alarm: Alarm) {
        guard alarm.isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Wake Protocol"
        content.body = alarm.label.isEmpty ? "Time to wake up!" : alarm.label
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "ALARM"
        // Time-sensitive: fires when screen is locked, can break through Focus (needs capability in Xcode)
        content.interruptionLevel = .timeSensitive

        if alarm.repeatDays.isEmpty {
            // One-time alarm
            var dateComponents = DateComponents()
            dateComponents.hour = alarm.hour
            dateComponents.minute = alarm.minute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: alarm.id.uuidString,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        } else {
            // Repeating alarm — one notification per day
            for day in alarm.repeatDays {
                var dateComponents = DateComponents()
                dateComponents.hour = alarm.hour
                dateComponents.minute = alarm.minute
                dateComponents.weekday = day + 1 // Calendar uses 1=Sunday

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: true
                )

                let request = UNNotificationRequest(
                    identifier: "\(alarm.id.uuidString)-\(day)",
                    content: content,
                    trigger: trigger
                )

                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    /// Cancel all notifications for an alarm
    func cancel(_ alarm: Alarm) {
        var identifiers = [alarm.id.uuidString]
        for day in 0..<7 {
            identifiers.append("\(alarm.id.uuidString)-\(day)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }

    /// Reschedule all enabled alarms
    func rescheduleAll(_ alarms: [Alarm]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for alarm in alarms where alarm.isEnabled {
            schedule(alarm)
        }
    }
}
