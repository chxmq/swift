import SwiftUI
import UserNotifications

@main
struct WakeProtocolApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}

/// App delegate — handles notification presentation and alarm trigger
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// If the app was launched from a notification tap, store alarmId until ContentView reads it
    static var pendingAlarmId: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    private static func baseAlarmId(from identifier: String) -> String {
        identifier.components(separatedBy: "-").prefix(5).joined(separator: "-")
    }

    private func postAlarmTriggered(alarmId: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .alarmTriggered,
                object: nil,
                userInfo: ["alarmId": alarmId]
            )
        }
    }

    /// When alarm fires in foreground: show only our full-screen alarm (no system banner)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let baseId = Self.baseAlarmId(from: notification.request.identifier)
        postAlarmTriggered(alarmId: baseId)
        // Don't show banner/sound — our full-screen AlarmFlowView and AlarmSoundManager handle it
        completionHandler([])
    }

    /// When user taps notification (background or cold start): trigger alarm UI
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let baseId = Self.baseAlarmId(from: response.notification.request.identifier)
        Self.pendingAlarmId = baseId
        postAlarmTriggered(alarmId: baseId)
        completionHandler()
    }
}

extension Notification.Name {
    static let alarmTriggered = Notification.Name("alarmTriggered")
}
