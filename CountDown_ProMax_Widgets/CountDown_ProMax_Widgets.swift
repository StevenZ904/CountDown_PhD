import WidgetKit
import SwiftUI

// MARK: - Shared Constants (duplicated from main app since widget is separate target)

private enum WidgetConstants {
    static let appGroupID = "group.sz904.CountDown-ProMax"
    static let snapshotsKey = "countdownSnapshots"
    static let urlScheme = "countdownpromax"

    static func deepLink(for id: UUID) -> URL {
        URL(string: "\(urlScheme)://open?id=\(id.uuidString)")!
    }

    static var openAppURL: URL {
        URL(string: "\(urlScheme)://open")!
    }
}

// MARK: - Shared Snapshot Model (must match main app's CountdownSnapshot)

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
    // Timezone fields
    let deadlineSemanticsRaw: String
    let deadlineTimeZoneID: String?
    // Milestone summary
    let nextMilestoneTitle: String?
    let nextMilestoneDate: Date?

    var swiftUIColor: Color {
        switch colorRaw {
        case "red": .red
        case "orange": .orange
        case "yellow": .yellow
        case "green": .green
        case "teal": .teal
        case "blue": .blue
        case "indigo": .indigo
        case "purple": .purple
        case "pink": .pink
        default: .blue
        }
    }

    var isOverdue: Bool { deadline < Date.now }

    var timeZoneBadge: String? {
        switch deadlineSemanticsRaw {
        case "aoe": return "AoE"
        case "timeZone":
            if let id = deadlineTimeZoneID {
                return TimeZone(identifier: id)?.abbreviation() ?? id
            }
            return nil
        default: return nil
        }
    }
}

// MARK: - Read snapshots from App Group

private func loadSnapshots() -> [CountdownSnapshot] {
    let defaults = UserDefaults(suiteName: WidgetConstants.appGroupID)
    guard let data = defaults?.data(forKey: WidgetConstants.snapshotsKey),
          let snapshots = try? JSONDecoder().decode([CountdownSnapshot].self, from: data)
    else {
        return []
    }
    // Pinned first, then by priority rank (orderIndex)
    return snapshots.sorted { a, b in
        if a.pinned != b.pinned { return a.pinned }
        return a.orderIndex < b.orderIndex
    }
}

// MARK: - Countdown Formatting (lightweight version for widget)

private func formatCountdown(_ snapshot: CountdownSnapshot, at date: Date) -> String {
    let interval = snapshot.deadline.timeIntervalSince(date)

    if interval <= 0 {
        if snapshot.overdueBehaviorRaw == "freezeAtZero" { return "Done" }
        let absInterval = abs(interval)
        return "-\(formatInterval(absInterval, showSeconds: snapshot.showSeconds))"
    }

    return formatInterval(interval, showSeconds: snapshot.showSeconds)
}

private func formatInterval(_ interval: TimeInterval, showSeconds: Bool) -> String {
    let total = Int(interval)
    let days = total / 86400
    let hours = (total % 86400) / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60

    if days > 0 {
        return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
    }
    if hours > 0 {
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
    if minutes > 0 {
        return showSeconds ? "\(minutes)m \(seconds)s" : "\(minutes)m"
    }
    return "\(seconds)s"
}

// MARK: - Timeline Entry

struct CountdownEntry: TimelineEntry {
    let date: Date
    let snapshots: [CountdownSnapshot]
}

// MARK: - Single Countdown Provider

struct SingleProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now, snapshots: [
            CountdownSnapshot(
                id: UUID(), title: "Sample", deadline: Date.now.addingTimeInterval(86400),
                colorRaw: "blue", unitModeRaw: "auto", fixedUnitRaw: nil,
                showSeconds: false, overdueBehaviorRaw: "showOverdue",
                pinned: true, orderIndex: 0,
                deadlineSemanticsRaw: "local", deadlineTimeZoneID: nil,
                nextMilestoneTitle: nil, nextMilestoneDate: nil
            )
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let snapshots = Array(loadSnapshots().prefix(1))
        completion(CountdownEntry(date: .now, snapshots: snapshots))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let snapshots = Array(loadSnapshots().prefix(1))
        var entries: [CountdownEntry] = []
        let now = Date()

        // Generate entries every 15 minutes for the next 4 hours
        for minuteOffset in stride(from: 0, through: 240, by: 15) {
            let entryDate = now.addingTimeInterval(Double(minuteOffset) * 60)
            entries.append(CountdownEntry(date: entryDate, snapshots: snapshots))
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Multi Countdown Provider

struct MultiProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now, snapshots: [
            CountdownSnapshot(
                id: UUID(), title: "Project Due", deadline: Date.now.addingTimeInterval(86400),
                colorRaw: "blue", unitModeRaw: "auto", fixedUnitRaw: nil,
                showSeconds: false, overdueBehaviorRaw: "showOverdue",
                pinned: true, orderIndex: 0,
                deadlineSemanticsRaw: "local", deadlineTimeZoneID: nil,
                nextMilestoneTitle: nil, nextMilestoneDate: nil
            ),
            CountdownSnapshot(
                id: UUID(), title: "Meeting", deadline: Date.now.addingTimeInterval(3600),
                colorRaw: "red", unitModeRaw: "auto", fixedUnitRaw: nil,
                showSeconds: false, overdueBehaviorRaw: "showOverdue",
                pinned: false, orderIndex: 1,
                deadlineSemanticsRaw: "local", deadlineTimeZoneID: nil,
                nextMilestoneTitle: nil, nextMilestoneDate: nil
            ),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let snapshots = Array(loadSnapshots().prefix(6))
        completion(CountdownEntry(date: .now, snapshots: snapshots))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let snapshots = Array(loadSnapshots().prefix(6))
        var entries: [CountdownEntry] = []
        let now = Date()

        for minuteOffset in stride(from: 0, through: 240, by: 15) {
            let entryDate = now.addingTimeInterval(Double(minuteOffset) * 60)
            entries.append(CountdownEntry(date: entryDate, snapshots: snapshots))
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Single Countdown Widget View

struct SingleCountdownWidgetView: View {
    let entry: CountdownEntry

    var body: some View {
        if let countdown = entry.snapshots.first {
            VStack(spacing: 4) {
                Text(countdown.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                Text(countdown.deadline, style: .timer)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(countdown.isOverdue ? .red : .primary)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(WidgetConstants.deepLink(for: countdown.id))
        } else {
            VStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No Countdowns")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Add one in the app")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .widgetURL(WidgetConstants.openAppURL)
        }
    }

}

// MARK: - Multi Countdown Widget View

struct MultiCountdownWidgetView: View {
    let entry: CountdownEntry
    @Environment(\.widgetFamily) var family

    private var maxItems: Int {
        family == .systemSmall ? 4 : 5
    }

    var body: some View {
        if entry.snapshots.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No Countdowns")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if family == .systemSmall {
            smallWidgetBody
        } else {
            listWidgetBody
        }
    }

    // MARK: - Small Widget: 2x2 Grid of Blocks

    private var smallWidgetBody: some View {
        let items = Array(entry.snapshots.prefix(4))
        return VStack(spacing: 4) {
            HStack(spacing: 4) {
                if items.count > 0 { smallBlock(for: items[0]) }
                if items.count > 1 { smallBlock(for: items[1]) }
            }
            HStack(spacing: 4) {
                if items.count > 2 { smallBlock(for: items[2]) }
                if items.count > 3 { smallBlock(for: items[3]) }
                // Fill empty slot if only 3 items
                if items.count == 3 {
                    Color.clear
                }
            }
        }
    }

    private func smallBlock(for countdown: CountdownSnapshot) -> some View {
        Link(destination: WidgetConstants.deepLink(for: countdown.id)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(countdown.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                Text(formatCountdown(countdown, at: entry.date))
                    .font(.callout)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(countdown.isOverdue ? .red : .primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Medium/Large Widget: Row List

    private var listWidgetBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(entry.snapshots.prefix(maxItems))) { countdown in
                Link(destination: WidgetConstants.deepLink(for: countdown.id)) {
                    HStack(spacing: 6) {
                        Text(countdown.title)
                            .font(.callout)
                            .lineLimit(1)

                        if let badge = countdown.timeZoneBadge {
                            Text(badge)
                                .font(.system(size: 9))
                                .foregroundStyle(.blue)
                        }

                        Spacer()

                        Text(formatCountdown(countdown, at: entry.date))
                            .font(.callout)
                            .fontWeight(.medium)
                            .monospacedDigit()
                            .foregroundStyle(countdown.isOverdue ? .red : .primary)
                    }
                }
            }
        }
    }
}

// MARK: - Widget Definitions

struct SingleCountdownWidget: Widget {
    let kind = "SingleCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SingleProvider()) { entry in
            SingleCountdownWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Countdown")
        .description("Shows your top countdown at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

struct MultiCountdownWidget: Widget {
    let kind = "MultiCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MultiProvider()) { entry in
            MultiCountdownWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Countdowns")
        .description("Shows your top countdowns by priority.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
