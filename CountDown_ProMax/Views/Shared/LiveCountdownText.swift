import SwiftUI

struct LiveCountdownText: View {
    let deadline: Date
    var unitMode: UnitMode = .auto
    var fixedUnit: FixedUnit? = nil
    var showSeconds: Bool = false
    var overdueBehavior: OverdueBehavior = .showOverdue
    var font: Font = .title2

    /// Update every second when showing seconds or when close to deadline / overdue.
    /// Otherwise update every 10 seconds for a responsive but efficient feel.
    private var updateInterval: TimeInterval {
        if showSeconds { return 1.0 }
        let remaining = deadline.timeIntervalSinceNow
        // Near deadline (< 5 min) or overdue: update every second
        if remaining < 300 || remaining < 0 { return 1.0 }
        return 10.0
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: updateInterval)) { context in
            Text(CountdownFormatter.format(
                deadline: deadline,
                now: context.date,
                unitMode: unitMode,
                fixedUnit: fixedUnit,
                showSeconds: showSeconds,
                overdueBehavior: overdueBehavior
            ))
            .font(font)
            .monospacedDigit()
            .contentTransition(.numericText())
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LiveCountdownText(deadline: Date.now.addingTimeInterval(3600))
        LiveCountdownText(deadline: Date.now.addingTimeInterval(90000), unitMode: .mixed)
        LiveCountdownText(deadline: Date.now.addingTimeInterval(-600), overdueBehavior: .showOverdue)
    }
    .padding()
}
