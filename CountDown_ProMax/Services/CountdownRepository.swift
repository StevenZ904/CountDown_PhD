import Foundation
import SwiftData

struct CountdownRepository {

    /// Fetches countdowns matching the given filter and sort option.
    static func fetch(
        context: ModelContext,
        filter: SmartViewFilter = .all,
        sort: SortOption = .soonest
    ) -> [Countdown] {
        let descriptor = FetchDescriptor<Countdown>(sortBy: [SortDescriptor(\.deadline)])

        guard let all = try? context.fetch(descriptor) else { return [] }

        let filtered: [Countdown]
        switch filter {
        case .all:
            filtered = all
        case .pinned:
            filtered = all.filter(\.pinned)
        case .endingSoon:
            filtered = all.filter(\.isEndingSoon)
        case .overdue:
            filtered = all.filter(\.isOverdue)
        }

        return sorted(filtered, by: sort)
    }

    /// Creates and inserts a new countdown with a computed order index.
    @discardableResult
    static func create(
        context: ModelContext,
        title: String,
        deadline: Date,
        mode: CountdownMode = .fixedDeadline,
        color: ColorToken = .blue,
        unitMode: UnitMode = .auto,
        fixedUnit: FixedUnit? = nil,
        showSeconds: Bool = false,
        pinned: Bool = false,
        notes: String? = nil,
        overdueBehavior: OverdueBehavior = .showOverdue,
        notificationRules: [NotificationRule] = []
    ) -> Countdown {
        let orderIndex = nextOrderIndex(context: context)
        let countdown = Countdown(
            title: title,
            deadline: deadline,
            mode: mode,
            color: color,
            unitMode: unitMode,
            fixedUnit: fixedUnit,
            showSeconds: showSeconds,
            pinned: pinned,
            orderIndex: orderIndex,
            notes: notes,
            overdueBehavior: overdueBehavior,
            notificationRules: notificationRules
        )
        context.insert(countdown)
        return countdown
    }

    /// Deletes a countdown and cancels its notifications.
    static func delete(context: ModelContext, countdown: Countdown) {
        let countdownID = countdown.id
        context.delete(countdown)
        Task {
            await NotificationService.shared.cancelNotifications(for: countdownID)
        }
    }

    /// Computes the next order index for manual sorting.
    static func nextOrderIndex(context: ModelContext) -> Double {
        let descriptor = FetchDescriptor<Countdown>(
            sortBy: [SortDescriptor(\.orderIndex, order: .reverse)]
        )
        let top = try? context.fetch(descriptor).first
        return (top?.orderIndex ?? 0) + 1.0
    }

    // MARK: - Private

    private static func sorted(_ countdowns: [Countdown], by sort: SortOption) -> [Countdown] {
        switch sort {
        case .soonest:
            return countdowns.sorted { a, b in
                if a.pinned != b.pinned { return a.pinned }
                return a.deadline < b.deadline
            }
        case .manual:
            return countdowns.sorted { a, b in
                if a.pinned != b.pinned { return a.pinned }
                return a.orderIndex < b.orderIndex
            }
        case .title:
            return countdowns.sorted {
                $0.title.localizedCompare($1.title) == .orderedAscending
            }
        }
    }
}
