import Foundation

struct NotificationRule: Codable, Sendable, Hashable, Identifiable {
    var id: UUID
    var type: RuleType
    var offsetSeconds: Int // 0 for .atTime; positive for .beforeTime

    enum RuleType: String, Codable, Sendable {
        case atTime
        case beforeTime
    }

    init(id: UUID = UUID(), type: RuleType, offsetSeconds: Int = 0) {
        self.id = id
        self.type = type
        self.offsetSeconds = offsetSeconds
    }

    // MARK: - Presets

    static let atDeadline = NotificationRule(type: .atTime, offsetSeconds: 0)
    static let fiveMinBefore = NotificationRule(type: .beforeTime, offsetSeconds: 300)
    static let fifteenMinBefore = NotificationRule(type: .beforeTime, offsetSeconds: 900)
    static let oneHourBefore = NotificationRule(type: .beforeTime, offsetSeconds: 3600)
    static let oneDayBefore = NotificationRule(type: .beforeTime, offsetSeconds: 86400)

    static let allPresets: [NotificationRule] = [
        .atDeadline,
        .fiveMinBefore,
        .fifteenMinBefore,
        .oneHourBefore,
        .oneDayBefore,
    ]

    var displayName: String {
        switch type {
        case .atTime:
            return "At deadline"
        case .beforeTime:
            let minutes = offsetSeconds / 60
            if minutes < 60 {
                return "\(minutes)m before"
            }
            let hours = minutes / 60
            if hours < 24 {
                return "\(hours)h before"
            }
            let days = hours / 24
            return "\(days)d before"
        }
    }
}
