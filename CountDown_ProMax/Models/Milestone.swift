import Foundation

/// A checkpoint within a countdown, stored as a Codable blob in Countdown.milestonesData.
struct Milestone: Codable, Identifiable, Sendable {
    var id: UUID
    var title: String
    var date: Date
    var isDone: Bool

    init(id: UUID = UUID(), title: String, date: Date, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.date = date
        self.isDone = isDone
    }
}
