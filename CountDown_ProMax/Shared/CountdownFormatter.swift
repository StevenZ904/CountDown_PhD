import Foundation

struct CountdownFormatter {

    /// Formats the remaining time between `now` and `deadline` based on display settings.
    static func format(
        deadline: Date,
        now: Date = .now,
        unitMode: UnitMode = .auto,
        fixedUnit: FixedUnit? = nil,
        showSeconds: Bool = false,
        overdueBehavior: OverdueBehavior = .showOverdue
    ) -> String {
        let interval = deadline.timeIntervalSince(now)

        // Handle overdue
        if interval <= 0 {
            switch overdueBehavior {
            case .freezeAtZero:
                return "0s"
            case .showOverdue:
                let overdueText = formatInterval(abs(interval), unitMode: unitMode, fixedUnit: fixedUnit, showSeconds: showSeconds)
                return "Overdue by \(overdueText)"
            }
        }

        let text = formatInterval(interval, unitMode: unitMode, fixedUnit: fixedUnit, showSeconds: showSeconds)
        return "\(text) left"
    }

    // MARK: - Private

    private static func formatInterval(
        _ interval: TimeInterval,
        unitMode: UnitMode,
        fixedUnit: FixedUnit?,
        showSeconds: Bool
    ) -> String {
        switch unitMode {
        case .auto:
            return formatAuto(interval, showSeconds: showSeconds)
        case .fixed:
            return formatFixed(interval, unit: fixedUnit ?? .days)
        case .mixed:
            return formatMixed(interval, showSeconds: showSeconds)
        }
    }

    /// Auto mode: shows the two largest meaningful units.
    private static func formatAuto(_ interval: TimeInterval, showSeconds: Bool) -> String {
        let totalSeconds = Int(interval)

        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if days > 0 {
            if hours > 0 {
                return "\(days)d \(hours)h"
            }
            return "\(days)d"
        }

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }

        if minutes > 0 {
            if showSeconds {
                return "\(minutes)m \(seconds)s"
            }
            return "\(minutes)m"
        }

        return "\(seconds)s"
    }

    /// Fixed mode: shows only one unit.
    private static func formatFixed(_ interval: TimeInterval, unit: FixedUnit) -> String {
        let totalSeconds = interval

        switch unit {
        case .years:
            let value = totalSeconds / (365.25 * 86400)
            return String(format: "%.1f years", value)
        case .months:
            let value = totalSeconds / (30.44 * 86400)
            return String(format: "%.1f months", value)
        case .days:
            let value = totalSeconds / 86400
            return String(format: "%.1f days", value)
        case .hours:
            let value = totalSeconds / 3600
            return String(format: "%.1f hours", value)
        case .minutes:
            let value = totalSeconds / 60
            return String(format: "%.0f minutes", value)
        case .seconds:
            return "\(Int(totalSeconds)) seconds"
        }
    }

    /// Mixed mode: shows all non-zero units.
    private static func formatMixed(_ interval: TimeInterval, showSeconds: Bool) -> String {
        let totalSeconds = Int(interval)

        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 { parts.append("\(minutes)m") }
        if showSeconds || parts.isEmpty { parts.append("\(seconds)s") }

        return parts.joined(separator: " ")
    }

    // MARK: - Share Formatting (Issue 3)

    /// Formats a single countdown for clipboard copy.
    /// Example: "ICML 2025: 3d 4h left (deadline: Aug 15 11:59 PM AoE · Aug 15 8:59 PM PDT)"
    static func shareSummary(for countdown: Countdown) -> String {
        let timeLeft = format(
            deadline: countdown.deadline,
            unitMode: .auto,
            showSeconds: false,
            overdueBehavior: countdown.overdueBehavior
        )

        var result = "\(countdown.title): \(timeLeft)"

        if countdown.deadlineSemantics != .local {
            let originalFormatter = DateFormatter()
            originalFormatter.dateFormat = "MMM d, h:mm a"
            originalFormatter.timeZone = countdown.effectiveTimeZone
            let originalText = originalFormatter.string(from: countdown.deadline)
            let badge = countdown.timeZoneBadge ?? ""

            let localFormatter = DateFormatter()
            localFormatter.dateFormat = "MMM d, h:mm a zzz"
            localFormatter.timeZone = .current
            let localText = localFormatter.string(from: countdown.deadline)

            result += " (deadline: \(originalText) \(badge) · \(localText))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            formatter.timeZone = .current
            result += " (deadline: \(formatter.string(from: countdown.deadline)))"
        }

        return result
    }

    /// Formats multiple countdowns as a bullet list for clipboard copy.
    static func shareSummary(for countdowns: [Countdown]) -> String {
        countdowns.map { "• \(shareSummary(for: $0))" }.joined(separator: "\n")
    }
}
