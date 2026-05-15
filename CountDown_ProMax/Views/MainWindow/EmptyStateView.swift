import SwiftUI

struct EmptyStateView: View {
    let filter: SmartViewFilter

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyIcon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(emptyTitle)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(emptySubtitle)
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            if filter == .all {
                Button {
                    NotificationCenter.default.post(name: .createNewCountdown, object: nil)
                } label: {
                    Label("Create Countdown", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyIcon: String {
        switch filter {
        case .all: "timer"
        case .pinned: "pin.slash"
        case .endingSoon: "clock"
        case .overdue: "checkmark.circle"
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .all: "No Countdowns"
        case .pinned: "No Pinned Countdowns"
        case .endingSoon: "Nothing Ending Soon"
        case .overdue: "Nothing Overdue"
        }
    }

    private var emptySubtitle: String {
        switch filter {
        case .all: "Create your first countdown to get started."
        case .pinned: "Pin a countdown to keep it visible here."
        case .endingSoon: "No countdowns ending in the next 72 hours."
        case .overdue: "All your countdowns are on track!"
        }
    }
}

#Preview {
    EmptyStateView(filter: .all)
}
