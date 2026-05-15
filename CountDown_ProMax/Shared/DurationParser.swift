import Foundation

struct DurationParser {

    /// Parses a human-readable duration string into a TimeInterval.
    ///
    /// Supported formats:
    /// - "3d 4h 10m" → 3 days, 4 hours, 10 minutes
    /// - "2h30m" → 2 hours, 30 minutes
    /// - "90m" → 90 minutes
    /// - "1d" → 1 day
    /// - "45s" → 45 seconds
    ///
    /// Returns `nil` if the string contains no valid duration components.
    static func parse(_ input: String) -> TimeInterval? {
        let trimmed = input.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return nil }

        let pattern = /(\d+)\s*(d|h|m|s)/
        var totalSeconds: TimeInterval = 0
        var foundMatch = false

        for match in trimmed.matches(of: pattern) {
            guard let value = Double(match.1) else { continue }
            let unit = String(match.2)
            foundMatch = true

            switch unit {
            case "d": totalSeconds += value * 86400
            case "h": totalSeconds += value * 3600
            case "m": totalSeconds += value * 60
            case "s": totalSeconds += value
            default: break
            }
        }

        return foundMatch ? totalSeconds : nil
    }

    /// Formats a TimeInterval into a human-readable duration string.
    /// Useful for pre-filling the duration input field.
    static func format(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(abs(interval))

        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 { parts.append("\(minutes)m") }

        return parts.isEmpty ? "0m" : parts.joined(separator: " ")
    }
}
