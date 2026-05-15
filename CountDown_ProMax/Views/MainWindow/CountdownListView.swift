import SwiftUI
import SwiftData
import AppKit

struct CountdownListView: View {
    let filter: SmartViewFilter
    @Binding var sortOption: SortOption
    @Binding var selectedCountdown: Countdown?

    @Query(sort: \Countdown.deadline) private var allCountdowns: [Countdown]
    @Environment(\.modelContext) private var modelContext

    @State private var draggingCountdownID: UUID?

    var filteredCountdowns: [Countdown] {
        let filtered: [Countdown]
        switch filter {
        case .all:
            filtered = allCountdowns
        case .pinned:
            filtered = allCountdowns.filter(\.pinned)
        case .endingSoon:
            filtered = allCountdowns.filter(\.isEndingSoon)
        case .overdue:
            filtered = allCountdowns.filter(\.isOverdue)
        }
        return sorted(filtered)
    }

    var body: some View {
        Group {
            if filteredCountdowns.isEmpty {
                EmptyStateView(filter: filter)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredCountdowns, id: \.id) { countdown in
                            CountdownCardView(countdown: countdown) {
                                selectedCountdown = countdown
                            }
                            .contextMenu {
                                contextMenu(for: countdown)
                            }
                            .opacity(draggingCountdownID == countdown.id ? 0.4 : 1.0)
                            .draggable(countdown.id.uuidString) {
                                // Drag preview
                                CountdownCardView(countdown: countdown)
                                    .frame(width: 300)
                                    .opacity(0.8)
                            }
                            .dropDestination(for: String.self) { items, _ in
                                guard let draggedIDString = items.first,
                                      let draggedID = UUID(uuidString: draggedIDString) else { return false }
                                return reorderCountdown(draggedID: draggedID, targetID: countdown.id)
                            } isTargeted: { isTargeted in
                                // Optional: visual feedback when hovering
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(filter.displayName)
    }

    // MARK: - Drag to Reorder

    private func reorderCountdown(draggedID: UUID, targetID: UUID) -> Bool {
        guard draggedID != targetID else { return false }

        // Auto-switch to manual sort if not already
        if sortOption != .manual {
            sortOption = .manual
        }

        var items = filteredCountdowns
        guard let fromIndex = items.firstIndex(where: { $0.id == draggedID }),
              let toIndex = items.firstIndex(where: { $0.id == targetID }) else { return false }

        let movedItem = items.remove(at: fromIndex)
        items.insert(movedItem, at: toIndex)

        // Reassign orderIndex sequentially
        for (index, countdown) in items.enumerated() {
            let newIndex = Double(index)
            if countdown.orderIndex != newIndex {
                countdown.orderIndex = newIndex
                countdown.updatedAt = .now
            }
        }

        // Sync widgets immediately
        WidgetDataBridge.writeSnapshots(from: allCountdowns)
        return true
    }

    // MARK: - Sorting

    private func sorted(_ countdowns: [Countdown]) -> [Countdown] {
        switch sortOption {
        case .soonest:
            // Pinned first, then by deadline ascending
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
            return countdowns.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenu(for countdown: Countdown) -> some View {
        Button {
            selectedCountdown = countdown
        } label: {
            Label("Edit", systemImage: "pencil")
        }

        Button {
            countdown.pinned.toggle()
            countdown.updatedAt = .now
        } label: {
            Label(
                countdown.pinned ? "Unpin" : "Pin",
                systemImage: countdown.pinned ? "pin.slash" : "pin"
            )
        }

        Button {
            let text = CountdownFormatter.shareSummary(for: countdown)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            NotificationCenter.default.post(name: .copiedToClipboard, object: nil)
        } label: {
            Label("Copy Summary", systemImage: "doc.on.doc")
        }

        Divider()

        Button(role: .destructive) {
            let countdownID = countdown.id
            modelContext.delete(countdown)
            Task {
                await NotificationService.shared.cancelNotifications(for: countdownID)
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

#Preview {
    CountdownListView(
        filter: .all,
        sortOption: .constant(.soonest),
        selectedCountdown: .constant(nil)
    )
    .modelContainer(for: Countdown.self, inMemory: true)
}
