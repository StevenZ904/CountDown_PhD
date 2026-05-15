import SwiftUI

struct DisplaySettingsSection: View {
    @Binding var unitMode: UnitMode
    @Binding var fixedUnit: FixedUnit
    @Binding var showSeconds: Bool
    @Binding var overdueBehavior: OverdueBehavior

    var body: some View {
        Section("Display") {
            Picker("Unit Mode", selection: $unitMode) {
                ForEach(UnitMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            if unitMode == .fixed {
                Picker("Fixed Unit", selection: $fixedUnit) {
                    ForEach(FixedUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            }

            Toggle("Show Seconds", isOn: $showSeconds)

            Picker("Overdue Behavior", selection: $overdueBehavior) {
                ForEach(OverdueBehavior.allCases, id: \.self) { behavior in
                    Text(behavior.displayName).tag(behavior)
                }
            }
        }
    }
}

#Preview {
    Form {
        DisplaySettingsSection(
            unitMode: .constant(.auto),
            fixedUnit: .constant(.days),
            showSeconds: .constant(false),
            overdueBehavior: .constant(.showOverdue)
        )
    }
    .padding()
    .frame(width: 400)
}
