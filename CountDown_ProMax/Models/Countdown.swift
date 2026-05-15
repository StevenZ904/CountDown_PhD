import Foundation
import SwiftData

@Model
final class Countdown {
    var id: UUID = UUID()
    var title: String = "New Countdown"
    var deadline: Date = Date.now
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    // Raw string storage for CloudKit compatibility
    var modeRaw: String = CountdownMode.fixedDeadline.rawValue
    var colorRaw: String = ColorToken.blue.rawValue
    var unitModeRaw: String = UnitMode.auto.rawValue
    var fixedUnitRaw: String?
    var overdueBehaviorRaw: String = OverdueBehavior.showOverdue.rawValue

    var showSeconds: Bool = false
    var pinned: Bool = false
    var orderIndex: Double = 0
    var tags: [String] = []
    var notes: String?

    // Notification rules stored as JSON Data
    var notificationRulesData: Data?

    // Deadline semantics (time zone handling)
    var deadlineSemanticsRaw: String = DeadlineSemantics.local.rawValue
    var deadlineTimeZoneID: String?

    // Milestones stored as JSON Data
    var milestonesData: Data?

    // MARK: - Computed Enum Accessors

    var mode: CountdownMode {
        get { CountdownMode(rawValue: modeRaw) ?? .fixedDeadline }
        set { modeRaw = newValue.rawValue }
    }

    var color: ColorToken {
        get { ColorToken(rawValue: colorRaw) ?? .blue }
        set { colorRaw = newValue.rawValue }
    }

    var unitMode: UnitMode {
        get { UnitMode(rawValue: unitModeRaw) ?? .auto }
        set { unitModeRaw = newValue.rawValue }
    }

    var fixedUnit: FixedUnit? {
        get {
            guard let raw = fixedUnitRaw else { return nil }
            return FixedUnit(rawValue: raw)
        }
        set { fixedUnitRaw = newValue?.rawValue }
    }

    var overdueBehavior: OverdueBehavior {
        get { OverdueBehavior(rawValue: overdueBehaviorRaw) ?? .showOverdue }
        set { overdueBehaviorRaw = newValue.rawValue }
    }

    var deadlineSemantics: DeadlineSemantics {
        get { DeadlineSemantics(rawValue: deadlineSemanticsRaw) ?? .local }
        set { deadlineSemanticsRaw = newValue.rawValue }
    }

    var deadlineTimeZone: TimeZone? {
        get {
            guard let id = deadlineTimeZoneID else { return nil }
            return TimeZone(identifier: id)
        }
        set { deadlineTimeZoneID = newValue?.identifier }
    }

    /// The effective timezone for display purposes.
    var effectiveTimeZone: TimeZone {
        switch deadlineSemantics {
        case .local: return .current
        case .aoe: return DeadlineSemantics.aoeTimeZone
        case .timeZone: return deadlineTimeZone ?? .current
        }
    }

    /// Short badge text for the timezone (e.g., "AoE", "ET", "PT")
    var timeZoneBadge: String? {
        switch deadlineSemantics {
        case .local: return nil
        case .aoe: return "AoE"
        case .timeZone:
            return deadlineTimeZone?.abbreviation() ?? deadlineTimeZoneID
        }
    }

    /// The deadline converted to the user's local time (for display when semantics != .local)
    var deadlineInLocalTime: String? {
        guard deadlineSemantics != .local else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter.string(from: deadline)
    }

    /// The deadline in its original timezone (for display)
    var deadlineInOriginalZone: String? {
        guard deadlineSemantics != .local else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = effectiveTimeZone
        return formatter.string(from: deadline)
    }

    var milestones: [Milestone] {
        get {
            guard let data = milestonesData else { return [] }
            return (try? JSONDecoder().decode([Milestone].self, from: data)) ?? []
        }
        set {
            milestonesData = try? JSONEncoder().encode(newValue)
        }
    }

    /// The next upcoming milestone that is not done.
    var nextMilestone: Milestone? {
        milestones
            .filter { !$0.isDone && $0.date >= Date.now }
            .sorted { $0.date < $1.date }
            .first
    }

    /// The earliest overdue milestone that is not done.
    var overdueMilestone: Milestone? {
        milestones
            .filter { !$0.isDone && $0.date < Date.now }
            .sorted { $0.date < $1.date }
            .first
    }

    var notificationRules: [NotificationRule] {
        get {
            guard let data = notificationRulesData else { return [] }
            return (try? JSONDecoder().decode([NotificationRule].self, from: data)) ?? []
        }
        set {
            notificationRulesData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Convenience

    var isOverdue: Bool {
        deadline < Date.now
    }

    var isEndingSoon: Bool {
        let hoursAhead = TimeInterval(AppConstants.endingSoonHours * 3600)
        return !isOverdue && deadline < Date.now.addingTimeInterval(hoursAhead)
    }

    // MARK: - Init

    init(
        title: String = "New Countdown",
        deadline: Date? = nil,
        mode: CountdownMode = .fixedDeadline,
        color: ColorToken = .blue,
        unitMode: UnitMode = .auto,
        fixedUnit: FixedUnit? = nil,
        showSeconds: Bool = false,
        pinned: Bool = false,
        orderIndex: Double = 0,
        tags: [String] = [],
        notes: String? = nil,
        overdueBehavior: OverdueBehavior = .showOverdue,
        notificationRules: [NotificationRule] = [],
        deadlineSemantics: DeadlineSemantics = .local,
        deadlineTimeZoneID: String? = nil,
        milestones: [Milestone] = []
    ) {
        self.id = UUID()
        self.title = title
        self.deadline = deadline ?? Self.nextFullHour()
        self.createdAt = Date.now
        self.updatedAt = Date.now
        self.modeRaw = mode.rawValue
        self.colorRaw = color.rawValue
        self.unitModeRaw = unitMode.rawValue
        self.fixedUnitRaw = fixedUnit?.rawValue
        self.showSeconds = showSeconds
        self.pinned = pinned
        self.orderIndex = orderIndex
        self.tags = tags
        self.notes = notes
        self.overdueBehaviorRaw = overdueBehavior.rawValue
        self.notificationRulesData = try? JSONEncoder().encode(notificationRules)
        self.deadlineSemanticsRaw = deadlineSemantics.rawValue
        self.deadlineTimeZoneID = deadlineTimeZoneID
        self.milestonesData = milestones.isEmpty ? nil : (try? JSONEncoder().encode(milestones))
    }

    // MARK: - Default Deadline

    static func nextFullHour(from date: Date = .now) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        guard let hourStart = calendar.date(from: components) else { return date }
        return hourStart.addingTimeInterval(3600)
    }
}
