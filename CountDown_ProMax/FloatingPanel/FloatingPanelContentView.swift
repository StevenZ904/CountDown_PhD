import SwiftUI
import SwiftData
import AppKit

/// SwiftUI view hosted inside the floating panel, showing up to 6 countdowns.
struct FloatingPanelContentView: View {
    @Query(sort: \Countdown.deadline) private var allCountdowns: [Countdown]

    /// Shows pinned first, then by priority rank, limited to 6.
    private var displayCountdowns: [Countdown] {
        let sorted = allCountdowns.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            return a.orderIndex < b.orderIndex
        }
        return Array(sorted.prefix(6))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Countdowns")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(displayCountdowns.count)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Divider()

            if displayCountdowns.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No countdowns")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(displayCountdowns, id: \.id) { countdown in
                            FloatingPanelRow(countdown: countdown)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(minWidth: 220, minHeight: 80)
    }
}

// MARK: - Floating Panel Row

private struct FloatingPanelRow: View {
    let countdown: Countdown

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(countdown.color.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(countdown.title)
                    .font(.callout)
                    .lineLimit(1)

                if let milestone = countdown.nextMilestone {
                    Text("▸ \(milestone.title)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 4) {
                    if let badge = countdown.timeZoneBadge {
                        Text(badge)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    LiveCountdownText(
                        deadline: countdown.deadline,
                        unitMode: countdown.unitMode,
                        fixedUnit: countdown.fixedUnit,
                        showSeconds: countdown.showSeconds,
                        overdueBehavior: countdown.overdueBehavior,
                        font: .callout
                    )
                    .foregroundStyle(countdown.isOverdue ? .red : .primary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                let text = CountdownFormatter.shareSummary(for: countdown)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                NotificationCenter.default.post(name: .copiedToClipboard, object: nil)
            } label: {
                Label("Copy Summary", systemImage: "doc.on.doc")
            }
        }
    }
}

#Preview {
    FloatingPanelContentView()
        .modelContainer(for: Countdown.self, inMemory: true)
        .frame(width: 280, height: 300)
}
