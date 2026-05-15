import SwiftUI

// MARK: - Countdown Mode

enum CountdownMode: String, Codable, Sendable {
    case fixedDeadline
    case durationToDeadline
}

// MARK: - Unit Display Mode

enum UnitMode: String, Codable, Sendable, CaseIterable {
    case auto
    case fixed
    case mixed

    var displayName: String {
        switch self {
        case .auto: "Auto"
        case .fixed: "Fixed Unit"
        case .mixed: "Mixed Units"
        }
    }
}

// MARK: - Fixed Unit Options

enum FixedUnit: String, Codable, Sendable, CaseIterable {
    case years
    case months
    case days
    case hours
    case minutes
    case seconds

    var displayName: String {
        switch self {
        case .years: "Years"
        case .months: "Months"
        case .days: "Days"
        case .hours: "Hours"
        case .minutes: "Minutes"
        case .seconds: "Seconds"
        }
    }
}

// MARK: - Overdue Behavior

enum OverdueBehavior: String, Codable, Sendable, CaseIterable {
    case showOverdue
    case freezeAtZero

    var displayName: String {
        switch self {
        case .showOverdue: "Show Overdue"
        case .freezeAtZero: "Freeze at Zero"
        }
    }
}

// MARK: - Color Token

enum ColorToken: String, Codable, Sendable, CaseIterable, Identifiable {
    case red
    case orange
    case yellow
    case green
    case teal
    case blue
    case indigo
    case purple
    case pink

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        }
    }

    var displayName: String { rawValue.capitalized }
}

// MARK: - Deadline Semantics (Time Zone Handling)

enum DeadlineSemantics: String, Codable, Sendable, CaseIterable {
    case local
    case timeZone
    case aoe // Anywhere on Earth (UTC-12)

    var displayName: String {
        switch self {
        case .local: "Local Time"
        case .timeZone: "Specific Time Zone"
        case .aoe: "Anywhere on Earth (AoE)"
        }
    }

    /// AoE is UTC-12 (Baker Island time) — the last timezone on Earth
    static let aoeTimeZone = TimeZone(secondsFromGMT: -12 * 3600)!
}

// MARK: - Sort Option

enum SortOption: String, Codable, Sendable, CaseIterable {
    case soonest
    case manual
    case title

    var displayName: String {
        switch self {
        case .soonest: "Soonest First"
        case .manual: "Manual Order"
        case .title: "By Title"
        }
    }
}

// MARK: - Smart View Filter

enum SmartViewFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case pinned
    case endingSoon
    case overdue

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: "All"
        case .pinned: "Pinned"
        case .endingSoon: "Ending Soon"
        case .overdue: "Overdue"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "list.bullet"
        case .pinned: "pin.fill"
        case .endingSoon: "clock.badge.exclamationmark"
        case .overdue: "exclamationmark.triangle"
        }
    }
}
