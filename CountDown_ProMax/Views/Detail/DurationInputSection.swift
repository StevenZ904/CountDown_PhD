import SwiftUI

struct DurationInputSection: View {
    @Binding var durationText: String
    @Binding var parsedDuration: TimeInterval?
    @Binding var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("e.g. 3d 4h 10m", text: $durationText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: durationText) { _, newValue in
                    parseDuration(newValue)
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let duration = parsedDuration {
                let futureDate = Date.now.addingTimeInterval(duration)
                Text("Will end: \(futureDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Format: 3d 4h 10m (days, hours, minutes, seconds)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func parseDuration(_ text: String) {
        guard !text.isEmpty else {
            parsedDuration = nil
            errorMessage = nil
            return
        }

        if let interval = DurationParser.parse(text) {
            parsedDuration = interval
            errorMessage = nil
        } else {
            parsedDuration = nil
            errorMessage = "Invalid format. Use combinations like 3d, 4h, 10m, 30s"
        }
    }
}

#Preview {
    Form {
        DurationInputSection(
            durationText: .constant("3d 4h"),
            parsedDuration: .constant(270000),
            errorMessage: .constant(nil)
        )
    }
    .padding()
    .frame(width: 400)
}
