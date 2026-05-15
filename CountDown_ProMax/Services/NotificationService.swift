import Foundation
import UserNotifications

final class NotificationService: Sendable {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func checkPermission() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule

    func scheduleNotifications(for countdown: Countdown) async {
        // Request permission if needed
        let status = await checkPermission()
        if status == .notDetermined {
            _ = await requestPermission()
        }

        // Cancel existing notifications for this countdown
        await cancelNotifications(for: countdown.id)

        let rules = countdown.notificationRules
        guard !rules.isEmpty else { return }

        for rule in rules {
            let fireDate: Date
            switch rule.type {
            case .atTime:
                fireDate = countdown.deadline
            case .beforeTime:
                fireDate = countdown.deadline.addingTimeInterval(-TimeInterval(rule.offsetSeconds))
            }

            // Skip if fire date is in the past
            guard fireDate > Date.now else { continue }

            let content = UNMutableNotificationContent()
            content.title = countdown.title

            switch rule.type {
            case .atTime:
                content.body = "Your countdown has reached its deadline!"
            case .beforeTime:
                let preset = NotificationRule(type: .beforeTime, offsetSeconds: rule.offsetSeconds)
                content.body = "Countdown ends \(preset.displayName.lowercased())."
            }

            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let identifier = notificationIdentifier(countdownID: countdown.id, ruleID: rule.id)
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                // Silently fail for individual notification scheduling
            }
        }
    }

    // MARK: - Cancel

    func cancelNotifications(for countdownID: UUID) async {
        let prefix = "countdown-\(countdownID.uuidString)"
        let requests = await center.pendingNotificationRequests()
        let idsToRemove = requests
            .filter { $0.identifier.hasPrefix(prefix) }
            .map(\.identifier)
        if !idsToRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }

    // MARK: - Reconcile (call on app launch)

    func reconcileAll(countdowns: [Countdown]) async {
        // Cancel all app notifications first
        center.removeAllPendingNotificationRequests()

        // Re-schedule for each countdown
        for countdown in countdowns {
            if !countdown.notificationRules.isEmpty {
                await scheduleNotifications(for: countdown)
            }
        }
    }

    // MARK: - Helpers

    private func notificationIdentifier(countdownID: UUID, ruleID: UUID) -> String {
        "countdown-\(countdownID.uuidString)-\(ruleID.uuidString)"
    }
}
