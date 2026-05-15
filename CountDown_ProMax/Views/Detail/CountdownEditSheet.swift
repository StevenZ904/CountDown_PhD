import SwiftUI
import SwiftData

struct CountdownEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let countdown: Countdown?

    // Form state
    @State private var title: String = ""
    @State private var deadline: Date = Countdown.nextFullHour()
    @State private var mode: CountdownMode = .fixedDeadline
    @State private var colorToken: ColorToken = .blue
    @State private var unitMode: UnitMode = .auto
    @State private var fixedUnit: FixedUnit = .days
    @State private var showSeconds: Bool = false
    @State private var pinned: Bool = false
    @State private var notes: String = ""
    @State private var overdueBehavior: OverdueBehavior = .showOverdue
    @State private var selectedRules: Set<Int> = [] // offsetSeconds values of selected presets

    @State private var durationText: String = ""
    @State private var durationError: String?
    @State private var parsedDuration: TimeInterval?

    // Deadline semantics (Issue 1)
    @State private var deadlineSemantics: DeadlineSemantics = .local
    @State private var deadlineTimeZoneID: String?

    // Milestones (Issue 2)
    @State private var milestones: [Milestone] = []

    private var isEditing: Bool { countdown != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text(isEditing ? "Edit Countdown" : "New Countdown")
                    .font(.headline)
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty
                              || (mode == .durationToDeadline && (parsedDuration == nil || parsedDuration! <= 0)))
            }
            .padding()

            Divider()

            Form {
                // Title
                Section("Title") {
                    TextField("Countdown name", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                // Deadline
                Section("Deadline") {
                    Picker("Input Method", selection: $mode) {
                        Text("Date & Time").tag(CountdownMode.fixedDeadline)
                        Text("Duration").tag(CountdownMode.durationToDeadline)
                    }
                    .pickerStyle(.segmented)

                    if mode == .fixedDeadline {
                        DateTimePickerSection(deadline: $deadline)
                    } else {
                        DurationInputSection(
                            durationText: $durationText,
                            parsedDuration: $parsedDuration,
                            errorMessage: $durationError
                        )
                    }

                    // Quick adjust buttons
                    HStack(spacing: 8) {
                        QuickAdjustButton(label: "+10m") { adjustTime(600) }
                        QuickAdjustButton(label: "+1h") { adjustTime(3600) }
                        QuickAdjustButton(label: "+1d") { adjustTime(86400) }
                        QuickAdjustButton(label: "EOD") {
                            if mode == .durationToDeadline {
                                let remaining = endOfDay().timeIntervalSince(.now)
                                parsedDuration = max(remaining, 0)
                                durationText = DurationParser.format(parsedDuration ?? 0)
                            } else {
                                deadline = endOfDay()
                            }
                        }
                        QuickAdjustButton(label: "EOW") {
                            if mode == .durationToDeadline {
                                let remaining = endOfWeek().timeIntervalSince(.now)
                                parsedDuration = max(remaining, 0)
                                durationText = DurationParser.format(parsedDuration ?? 0)
                            } else {
                                deadline = endOfWeek()
                            }
                        }
                    }
                }

                // Time zone semantics
                DeadlineSemanticsSection(
                    semantics: $deadlineSemantics,
                    timeZoneID: $deadlineTimeZoneID,
                    deadline: $deadline
                )

                // Preview
                Section("Preview") {
                    if mode == .durationToDeadline {
                        // Static preview based on parsed duration
                        Text(previewTextForDuration)
                            .font(.title)
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 4)
                    } else {
                        // Live countdown for fixed deadline
                        LiveCountdownText(
                            deadline: deadline,
                            unitMode: unitMode,
                            fixedUnit: unitMode == .fixed ? fixedUnit : nil,
                            showSeconds: showSeconds,
                            overdueBehavior: overdueBehavior,
                            font: .title
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    }
                }

                // Display settings
                DisplaySettingsSection(
                    unitMode: $unitMode,
                    fixedUnit: $fixedUnit,
                    showSeconds: $showSeconds,
                    overdueBehavior: $overdueBehavior
                )

                // Color
                ColorPickerSection(selectedColor: $colorToken)

                // Notifications
                NotificationRulesSection(selectedRules: $selectedRules)

                // Milestones
                MilestonesSection(milestones: $milestones)

                // Options
                Section("Options") {
                    Toggle("Pinned", isOn: $pinned)
                }

                // Notes
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }

                // Delete button (edit mode only)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            deleteCountdown()
                        } label: {
                            Label("Delete Countdown", systemImage: "trash")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 480, height: 700)
        .onAppear { loadExisting() }
    }

    // MARK: - Preview

    private var previewTextForDuration: String {
        guard let duration = parsedDuration, duration > 0 else {
            return "—"
        }
        return CountdownFormatter.format(
            deadline: Date.now.addingTimeInterval(duration),
            now: .now,
            unitMode: unitMode,
            fixedUnit: unitMode == .fixed ? fixedUnit : nil,
            showSeconds: showSeconds,
            overdueBehavior: overdueBehavior
        )
    }

    // MARK: - Adjust Time

    private func adjustTime(_ seconds: TimeInterval) {
        if mode == .durationToDeadline {
            let current = parsedDuration ?? 0
            parsedDuration = current + seconds
            durationText = DurationParser.format(parsedDuration ?? 0)
        } else {
            deadline = deadline.addingTimeInterval(seconds)
        }
    }

    // MARK: - Load Existing Countdown

    private func loadExisting() {
        guard let countdown else { return }
        title = countdown.title
        deadline = countdown.deadline
        mode = countdown.mode
        colorToken = countdown.color
        unitMode = countdown.unitMode
        fixedUnit = countdown.fixedUnit ?? .days
        showSeconds = countdown.showSeconds
        pinned = countdown.pinned
        notes = countdown.notes ?? ""
        overdueBehavior = countdown.overdueBehavior
        selectedRules = Set(countdown.notificationRules.map(\.offsetSeconds))

        deadlineSemantics = countdown.deadlineSemantics
        deadlineTimeZoneID = countdown.deadlineTimeZoneID
        milestones = countdown.milestones

        if mode == .durationToDeadline {
            let remaining = max(countdown.deadline.timeIntervalSince(.now), 0)
            parsedDuration = remaining
            durationText = DurationParser.format(remaining)
        }
    }

    // MARK: - Save

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        // In duration mode, compute the deadline NOW at save time
        let finalDeadline: Date
        if mode == .durationToDeadline, let duration = parsedDuration, duration > 0 {
            finalDeadline = Date.now.addingTimeInterval(duration)
        } else {
            finalDeadline = deadline
        }

        let rules = NotificationRule.allPresets.filter { selectedRules.contains($0.offsetSeconds) }

        if let countdown {
            // Edit existing
            countdown.title = trimmedTitle
            countdown.deadline = finalDeadline
            countdown.mode = mode
            countdown.color = colorToken
            countdown.unitMode = unitMode
            countdown.fixedUnit = unitMode == .fixed ? fixedUnit : nil
            countdown.showSeconds = showSeconds
            countdown.pinned = pinned
            countdown.notes = notes.isEmpty ? nil : notes
            countdown.overdueBehavior = overdueBehavior
            countdown.notificationRules = rules
            countdown.deadlineSemantics = deadlineSemantics
            countdown.deadlineTimeZoneID = deadlineTimeZoneID
            countdown.milestones = milestones
            countdown.updatedAt = .now
        } else {
            // Create new
            let nextIndex = CountdownRepository.nextOrderIndex(context: modelContext)
            let newCountdown = Countdown(
                title: trimmedTitle,
                deadline: finalDeadline,
                mode: mode,
                color: colorToken,
                unitMode: unitMode,
                fixedUnit: unitMode == .fixed ? fixedUnit : nil,
                showSeconds: showSeconds,
                pinned: pinned,
                orderIndex: nextIndex,
                notes: notes.isEmpty ? nil : notes,
                overdueBehavior: overdueBehavior,
                notificationRules: rules,
                deadlineSemantics: deadlineSemantics,
                deadlineTimeZoneID: deadlineTimeZoneID,
                milestones: milestones
            )
            modelContext.insert(newCountdown)

            Task {
                await NotificationService.shared.scheduleNotifications(for: newCountdown)
            }
        }

        if let countdown {
            Task {
                await NotificationService.shared.scheduleNotifications(for: countdown)
            }
        }

        dismiss()
    }

    // MARK: - Delete

    private func deleteCountdown() {
        guard let countdown else { return }
        let countdownID = countdown.id
        modelContext.delete(countdown)
        dismiss()
        Task {
            await NotificationService.shared.cancelNotifications(for: countdownID)
        }
    }

    // MARK: - Quick Adjust Helpers

    private func endOfDay() -> Date {
        let calendar = Calendar.current
        let today = Date.now
        guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: today) else {
            return today
        }
        // If already past 11:59 PM, return tomorrow's 11:59 PM
        if endOfDay < .now {
            return calendar.date(byAdding: .day, value: 1, to: endOfDay) ?? endOfDay
        }
        return endOfDay
    }

    private func endOfWeek() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSunday = (8 - weekday) % 7
        let targetDay = daysUntilSunday == 0 ? 7 : daysUntilSunday
        guard let nextSunday = calendar.date(byAdding: .day, value: targetDay, to: today),
              let endOfSunday = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: nextSunday) else {
            return today
        }
        return endOfSunday
    }
}

// MARK: - Quick Adjust Button

private struct QuickAdjustButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .controlSize(.small)
    }
}

#Preview {
    CountdownEditSheet(countdown: nil)
        .modelContainer(for: Countdown.self, inMemory: true)
}
