import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedFilter: SmartViewFilter
    @Query private var allCountdowns: [Countdown]

    var body: some View {
        List(SmartViewFilter.allCases, selection: $selectedFilter) { filter in
            Label {
                HStack {
                    Text(filter.displayName)
                    Spacer()
                    Text("\(count(for: filter))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
            } icon: {
                Image(systemName: filter.systemImage)
            }
            .tag(filter)
        }
        .listStyle(.sidebar)
        .navigationTitle("Countdown")
        .frame(minWidth: 180)
    }

    private func count(for filter: SmartViewFilter) -> Int {
        switch filter {
        case .all:
            return allCountdowns.count
        case .pinned:
            return allCountdowns.filter(\.pinned).count
        case .endingSoon:
            return allCountdowns.filter(\.isEndingSoon).count
        case .overdue:
            return allCountdowns.filter(\.isOverdue).count
        }
    }
}

#Preview {
    SidebarView(selectedFilter: .constant(.all))
        .modelContainer(for: Countdown.self, inMemory: true)
}
