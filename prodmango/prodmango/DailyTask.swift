import Foundation
import SwiftData

@Model
final class DailyTask {
    var id: UUID
    var title: String
    var notes: String
    var date: Date
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var timeEstimate: String?

    // Parent — every DailyTask belongs to exactly one Milestone.
    // (The inverse side of this relationship is declared on Milestone.)
    var milestone: Milestone?

    init(
        title: String,
        notes: String = "",
        date: Date = .now,
        milestone: Milestone,
        timeEstimate: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.date = date
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt = .now
        self.milestone = milestone
        self.timeEstimate = timeEstimate
    }

    /// Convenience: walk up the hierarchy to the ambition this single
    /// task ultimately serves.
    var ambition: Ambition? {
        milestone?.ambition
    }

    /// Flips completion state. Because `Ambition.progress` and
    /// `Milestone.progress` are computed live from these relationships,
    /// calling this is the only thing needed to "contribute" progress
    /// up the chain — no manual syncing required.
    func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? .now : nil
    }
}
