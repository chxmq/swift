import SwiftUI
import UserNotifications

@main
struct WakeProtocolApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

/// App delegate — handles notification presentation in foreground
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// Show alarm notification as a full banner even when the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner + sound + badge even in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap — post to show the alarm screen
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let alarmId = response.notification.request.identifier
        // Strip day suffix if present (repeating alarms use "id-day")
        let baseId = alarmId.components(separatedBy: "-").prefix(5).joined(separator: "-")

        // Post notification to trigger alarm UI
        NotificationCenter.default.post(
            name: .alarmTriggered,
            object: nil,
            userInfo: ["alarmId": baseId]
        )
        completionHandler()
    }
}

extension Notification.Name {
    static let alarmTriggered = Notification.Name("alarmTriggered")
}
