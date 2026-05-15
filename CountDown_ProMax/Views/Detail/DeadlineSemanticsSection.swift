import SwiftUI

/// Edit sheet section for choosing deadline time zone semantics (Local / Specific Time Zone / AoE).
struct DeadlineSemanticsSection: View {
    @Binding var semantics: DeadlineSemantics
    @Binding var timeZoneID: String?
    @Binding var deadline: Date

    /// Common conference time zones for quick access
    private static let commonZones: [(label: String, id: String)] = [
        ("US Eastern", "America/New_York"),
        ("US Pacific", "America/Los_Angeles"),
        ("US Central", "America/Chicago"),
        ("UTC", "UTC"),
        ("UK", "Europe/London"),
        ("Central Europe", "Europe/Berlin"),
        ("Japan", "Asia/Tokyo"),
        ("China", "Asia/Shanghai"),
    ]

    var body: some View {
        Section("Time Zone") {
            Picker("Deadline Semantics", selection: $semantics) {
                ForEach(DeadlineSemantics.allCases, id: \.self) { s in
                    Text(s.displayName).tag(s)
                }
            }
            .pickerStyle(.segmented)

            if semantics == .timeZone {
                Picker("Time Zone", selection: timeZoneBinding) {
                    ForEach(Self.commonZones, id: \.id) { zone in
                        Text("\(zone.label) (\(abbreviation(for: zone.id)))")
                            .tag(zone.id)
                    }
                    Divider()
                    ForEach(allSystemZoneIDs(), id: \.self) { id in
                        Text(id).tag(id)
                    }
                }
            }

            // Show conversion info for non-local semantics
            if semantics != .local {
                VStack(alignment: .leading, spacing: 4) {
                    if let originalText = originalZoneText {
                        HStack(spacing: 4) {
                            Text("Original:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(originalText)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }

                    HStack(spacing: 4) {
                        Text("Your local time:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(localTimeText)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .onChange(of: semantics) { _, newValue in
            // Set default timezone when switching to timeZone mode
            if newValue == .timeZone && timeZoneID == nil {
                timeZoneID = "America/New_York"
            }
            if newValue == .local || newValue == .aoe {
                timeZoneID = nil
            }
        }
    }

    // MARK: - Helpers

    private var timeZoneBinding: Binding<String> {
        Binding(
            get: { timeZoneID ?? "America/New_York" },
            set: { timeZoneID = $0 }
        )
    }

    private var effectiveTimeZone: TimeZone {
        switch semantics {
        case .local: .current
        case .aoe: DeadlineSemantics.aoeTimeZone
        case .timeZone:
            if let id = timeZoneID, let tz = TimeZone(identifier: id) {
                tz
            } else {
                .current
            }
        }
    }

    private var originalZoneText: String? {
        guard semantics != .local else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = effectiveTimeZone
        let badge = semantics == .aoe ? "AoE" : abbreviation(for: timeZoneID ?? "")
        return "\(formatter.string(from: deadline)) \(badge)"
    }

    private var localTimeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter.string(from: deadline)
    }

    private func abbreviation(for zoneID: String) -> String {
        TimeZone(identifier: zoneID)?.abbreviation() ?? zoneID
    }

    private func allSystemZoneIDs() -> [String] {
        TimeZone.knownTimeZoneIdentifiers.sorted()
    }
}
