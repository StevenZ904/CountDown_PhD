import Foundation
import WidgetKit

/// Lightweight snapshot of a Countdown for sharing with the widget extension
/// via App Group UserDefaults. Both the app and widget can decode this.
struct CountdownSnapshot: Codable, Sendable, Identifiable {
    let id: UUID
    let title: String
    let deadline: Date
    let colorRaw: String
    let unitModeRaw: String
    let fixedUnitRaw: String?
    let showSeconds: Bool
    let overdueBehaviorRaw: String
    let pinned: Bool
    let orderIndex: Double
    // Timezone fields (Issue 1)
    let deadlineSemanticsRaw: String
    let deadlineTimeZoneID: String?
    // Milestone summary fields (Issue 2)
    let nextMilestoneTitle: String?
    let nextMilestoneDate: Date?
}

/// Bridges countdown data between the main app and the widget extension
/// using a shared App Group UserDefaults suite.
struct WidgetDataBridge {
    private static let suiteName = AppConstants.appGroupID
    private static let snapshotsKey = "countdownSnapshots"

    /// Called by the main app after any CRUD operation to push fresh data to the widget.
    static func writeSnapshots(from countdowns: [Countdown]) {
        let snapshots = countdowns.map { countdown in
            let next = countdown.nextMilestone
            return CountdownSnapshot(
                id: countdown.id,
                title: countdown.title,
                deadline: countdown.deadline,
                colorRaw: countdown.colorRaw,
                unitModeRaw: countdown.unitModeRaw,
                fixedUnitRaw: countdown.fixedUnitRaw,
                showSeconds: countdown.showSeconds,
                overdueBehaviorRaw: countdown.overdueBehaviorRaw,
                pinned: countdown.pinned,
                orderIndex: countdown.orderIndex,
                deadlineSemanticsRaw: countdown.deadlineSemanticsRaw,
                deadlineTimeZoneID: countdown.deadlineTimeZoneID,
                nextMilestoneTitle: next?.title,
                nextMilestoneDate: next?.date
            )
        }

        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(data, forKey: snapshotsKey)

        // Tell WidgetKit to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Called by the widget extension to read the latest countdown data.
    static func readSnapshots() -> [CountdownSnapshot] {
        let defaults = UserDefaults(suiteName: suiteName)
        guard let data = defaults?.data(forKey: snapshotsKey),
              let snapshots = try? JSONDecoder().decode([CountdownSnapshot].self, from: data)
        else {
            return []
        }
        return snapshots
    }
}
