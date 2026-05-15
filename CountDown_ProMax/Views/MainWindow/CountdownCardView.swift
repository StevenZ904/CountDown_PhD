import SwiftUI

struct CountdownCardView: View {
    let countdown: Countdown
    var onEdit: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            // Color accent strip
            RoundedRectangle(cornerRadius: 2)
                .fill(countdown.color.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(countdown.title)
                        .font(.headline)
                        .lineLimit(1)

                    if countdown.pinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if let badge = countdown.timeZoneBadge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.15), in: Capsule())
                            .foregroundStyle(.blue)
                    }

                    Spacer()
                }

                LiveCountdownText(
                    deadline: countdown.deadline,
                    unitMode: countdown.unitMode,
                    fixedUnit: countdown.fixedUnit,
                    showSeconds: countdown.showSeconds,
                    overdueBehavior: countdown.overdueBehavior,
                    font: .title3
                )
                .foregroundStyle(countdown.isOverdue ? .red : .primary)

                // Local time conversion for non-local deadlines
                if let localTime = countdown.deadlineInLocalTime {
                    Text("Local: \(localTime)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Next milestone
                if let milestone = countdown.nextMilestone {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("Next: \(milestone.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else if let overdue = countdown.overdueMilestone {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                        Text("Overdue: \(overdue.title)")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    }
                }

                if let notes = countdown.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onEdit() }
    }
}

#Preview {
    let countdown = Countdown(
        title: "Project Deadline",
        deadline: Date.now.addingTimeInterval(86400 * 3),
        color: .purple,
        pinned: true,
        notes: "Don't forget to submit the report"
    )
    CountdownCardView(countdown: countdown)
        .padding()
        .frame(width: 350)
}
