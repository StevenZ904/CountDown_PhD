import SwiftUI

/// Edit sheet section for adding, editing, and deleting milestones within a countdown.
struct MilestonesSection: View {
    @Binding var milestones: [Milestone]

    @State private var newTitle: String = ""
    @State private var newDate: Date = .now.addingTimeInterval(86400)

    var body: some View {
        Section("Milestones") {
            // Existing milestones
            ForEach($milestones) { $milestone in
                HStack(spacing: 8) {
                    Button {
                        milestone.isDone.toggle()
                    } label: {
                        Image(systemName: milestone.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(milestone.isDone ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(milestone.title)
                            .font(.callout)
                            .strikethrough(milestone.isDone)
                            .foregroundStyle(milestone.isDone ? .secondary : .primary)

                        Text(milestone.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Status indicator
                    if !milestone.isDone {
                        if milestone.date < Date.now {
                            Text("overdue")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        } else {
                            Text(shortTimeLeft(to: milestone.date))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        removeMilestone(milestone)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }

            // Quick-add presets
            HStack(spacing: 6) {
                ForEach(["Draft done", "Experiments", "Figures", "Camera-ready"], id: \.self) { preset in
                    Button(preset) {
                        addMilestone(title: preset, date: Date.now.addingTimeInterval(86400 * 3))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }

            // Add new milestone
            HStack(spacing: 8) {
                TextField("Milestone title", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)

                DatePicker("", selection: $newDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .frame(width: 180)

                Button {
                    let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    addMilestone(title: trimmed, date: newDate)
                    newTitle = ""
                    newDate = .now.addingTimeInterval(86400)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func addMilestone(title: String, date: Date) {
        milestones.append(Milestone(title: title, date: date))
        milestones.sort { $0.date < $1.date }
    }

    private func removeMilestone(_ milestone: Milestone) {
        milestones.removeAll { $0.id == milestone.id }
    }

    private func shortTimeLeft(to date: Date) -> String {
        let interval = date.timeIntervalSince(.now)
        guard interval > 0 else { return "overdue" }
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        if days > 0 { return "\(days)d left" }
        if hours > 0 { return "\(hours)h left" }
        let minutes = (Int(interval) % 3600) / 60
        return "\(minutes)m left"
    }
}
