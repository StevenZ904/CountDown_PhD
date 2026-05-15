import AppKit
import UserNotifications
import WidgetKit

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        // Ensure the app activates and shows its window
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
                window.makeKeyAndOrderFront(nil)
            }
        }

        // Request notification permission on first launch
        Task {
            _ = await NotificationService.shared.requestPermission()
        }

        // Observe CloudKit remote changes to sync widgets
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(remoteStoreDidChange),
            name: NSNotification.Name("NSPersistentStoreRemoteChangeNotification"),
            object: nil
        )
    }

    @objc private func remoteStoreDidChange(_ notification: Notification) {
        // This fires on a background thread — dispatch UI work to main thread
        DispatchQueue.main.async {
            // When CloudKit pushes changes from another device, refresh widgets
            WidgetCenter.shared.reloadAllTimelines()

            // Post a notification so the UI can re-sync widget data bridge
            NotificationCenter.default.post(name: .cloudKitDataDidChange, object: nil)
        }
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let identifier = response.notification.request.identifier
        // Identifier format: "countdown-{UUID}-{ruleUUID}"
        // UUID has 5 groups: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
        let parts = identifier.split(separator: "-")
        if parts.count >= 6 {
            let uuidString = parts[1...5].joined(separator: "-")
            if let _ = UUID(uuidString: uuidString) {
                NotificationCenter.default.post(
                    name: .navigateToCountdown,
                    object: nil,
                    userInfo: ["countdownID": uuidString]
                )
            }
        }
    }
}

extension Notification.Name {
    static let navigateToCountdown = Notification.Name("navigateToCountdown")
    static let cloudKitDataDidChange = Notification.Name("cloudKitDataDidChange")
}
