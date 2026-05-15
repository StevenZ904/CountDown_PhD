import SwiftUI

struct NotificationRulesSection: View {
    @Binding var selectedRules: Set<Int> // Set of offsetSeconds values

    var body: some View {
        Section("Notifications") {
            ForEach(NotificationRule.allPresets) { preset in
                Toggle(preset.displayName, isOn: binding(for: preset.offsetSeconds))
            }
        }
    }

    private func binding(for offsetSeconds: Int) -> Binding<Bool> {
        Binding(
            get: { selectedRules.contains(offsetSeconds) },
            set: { isOn in
                if isOn {
                    selectedRules.insert(offsetSeconds)
                } else {
                    selectedRules.remove(offsetSeconds)
                }
            }
        )
    }
}

#Preview {
    Form {
        NotificationRulesSection(selectedRules: .constant([0, 300]))
    }
    .padding()
    .frame(width: 400)
}
