import Foundation
import SwiftData

@Model
final class Milestone {
    var id: UUID
    var title: String
    var details: String
    var startDate: Date
    var endDate: Date
    var isCompleted: Bool
    var createdAt: Date

    // Parent — every Milestone belongs to exactly one Ambition.
    var ambition: Ambition?

    // One Milestone -> many DailyTasks. Deleting the Milestone deletes
    // its tasks too.
    @Relationship(deleteRule: .cascade, inverse: \DailyTask.milestone)
    var dailyTasks: [DailyTask] = []

    init(
        title: String,
        details: String = "",
        startDate: Date,
        endDate: Date,
        ambition: Ambition? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.details = details
        self.startDate = startDate
        self.endDate = endDate
        self.isCompleted = false
        self.createdAt = .now
        self.ambition = ambition
    }

    /// Progress within this checkpoint alone.
    var progress: Double {
        guard !dailyTasks.isEmpty else { return 0 }
        let completed = dailyTasks.filter(\.isCompleted).count
        return Double(completed) / Double(dailyTasks.count)
    }
}
