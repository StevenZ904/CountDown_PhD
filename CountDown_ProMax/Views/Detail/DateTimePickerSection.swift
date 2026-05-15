import SwiftUI

struct DateTimePickerSection: View {
    @Binding var deadline: Date

    var body: some View {
        DatePicker(
            "Date & Time",
            selection: $deadline,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.stepperField)
    }
}

#Preview {
    Form {
        DateTimePickerSection(deadline: .constant(Date.now.addingTimeInterval(3600)))
    }
    .padding()
    .frame(width: 400)
}
