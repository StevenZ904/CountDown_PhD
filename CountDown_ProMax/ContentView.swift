import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @State private var selectedFilter: SmartViewFilter = .all
    @State private var showingNewCountdown = false
    @State private var selectedCountdown: Countdown?
    @State private var sortOption: SortOption = .soonest
    @State private var showWidgetPrompt = false
    @State private var showCopiedToast = false
    @AppStorage("hasSeenWidgetPrompt") private var hasSeenWidgetPrompt = false
    @AppStorage("hasRunOrderIndexMigration") private var hasRunOrderIndexMigration = false
    @Query(sort: \Countdown.deadline) private var allCountdowns: [Countdown]

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedFilter: $selectedFilter)
        } detail: {
            ZStack(alignment: .bottom) {
                CountdownListView(
                    filter: selectedFilter,
                    sortOption: $sortOption,
                    selectedCountdown: $selectedCountdown
                )

                // One-time widget setup prompt
                if showWidgetPrompt {
                    WidgetSetupBanner {
                        withAnimation { showWidgetPrompt = false }
                        hasSeenWidgetPrompt = true
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewCountdown = true
                    } label: {
                        Label("New Countdown", systemImage: "plus")
                    }
                }

                ToolbarItem {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Text(option.displayName)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewCountdown, onDismiss: onSheetDismiss) {
            CountdownEditSheet(countdown: nil)
        }
        .sheet(item: $selectedCountdown, onDismiss: syncWidgets) { countdown in
            CountdownEditSheet(countdown: countdown)
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewCountdown)) { _ in
            showingNewCountdown = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitDataDidChange)) { _ in
            syncWidgets()
        }
        .onReceive(NotificationCenter.default.publisher(for: .copyTopSummaries)) { _ in
            copyTopSummaries()
        }
        .onReceive(NotificationCenter.default.publisher(for: .copiedToClipboard)) { _ in
            showCopiedFeedback()
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                CopiedToastView()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onChange(of: allCountdowns.count) { _, _ in
            syncWidgets()
        }
        .onAppear {
            migrateOrderIndexIfNeeded()
            syncWidgets()
            Task {
                await NotificationService.shared.reconcileAll(countdowns: allCountdowns)
            }
        }
    }

    private func migrateOrderIndexIfNeeded() {
        guard !hasRunOrderIndexMigration else { return }

        let zeroIndexed = allCountdowns.filter { $0.orderIndex == 0 }
        guard zeroIndexed.count > 1 else {
            hasRunOrderIndexMigration = true
            return
        }

        // Assign orderIndex based on pinned-first + soonest-deadline
        let sorted = allCountdowns.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            return a.deadline < b.deadline
        }
        for (index, countdown) in sorted.enumerated() {
            countdown.orderIndex = Double(index)
            countdown.updatedAt = .now
        }
        hasRunOrderIndexMigration = true
    }

    private func syncWidgets() {
        WidgetDataBridge.writeSnapshots(from: allCountdowns)
    }

    private func onSheetDismiss() {
        syncWidgets()
        // Show widget prompt once after the first countdown is created
        if !hasSeenWidgetPrompt && !allCountdowns.isEmpty {
            withAnimation { showWidgetPrompt = true }
        }
    }

    private func copyTopSummaries() {
        let top6 = allCountdowns
            .sorted { a, b in
                if a.pinned != b.pinned { return a.pinned }
                return a.orderIndex < b.orderIndex
            }
            .prefix(6)
        let text = CountdownFormatter.shareSummary(for: Array(top6))
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        showCopiedFeedback()
    }

    private func showCopiedFeedback() {
        withAnimation { showCopiedToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showCopiedToast = false }
        }
    }
}

// MARK: - Copied Toast

private struct CopiedToastView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Copied to clipboard")
                .font(.callout)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 4, y: 2)
    }
}

// MARK: - Widget Setup Banner

private struct WidgetSetupBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "widget.small")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Add a Widget to Your Desktop")
                    .font(.headline)
                Text("Right-click your desktop, select \"Edit Widgets...\", then search for \"Countdown\" to add it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Got it", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 4, y: 2)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Countdown.self, inMemory: true)
}
