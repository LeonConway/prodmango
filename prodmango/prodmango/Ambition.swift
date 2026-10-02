import Foundation
import SwiftData

@Model
final class Ambition {
    var id: UUID
    var title: String
    var details: String
    var createdAt: Date
    var targetDate: Date?
    var isArchived: Bool

    // One Ambition -> many Milestones. Deleting the Ambition deletes
    // everything beneath it (its milestones, and in turn their tasks).
    @Relationship(deleteRule: .cascade, inverse: \Milestone.ambition)
    var milestones: [Milestone] = []

    init(
        title: String,
        details: String = "",
        targetDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.details = details
        self.createdAt = .now
        self.targetDate = targetDate
        self.isArchived = false
    }

    /// Overall progress toward this ambition, computed live from every
    /// daily task across every milestone beneath it. Nothing needs to be
    /// manually updated — toggling a DailyTask's completion is enough.
    var progress: Double {
        let allTasks = milestones.flatMap { $0.dailyTasks }
        guard !allTasks.isEmpty else { return 0 }
        let completed = allTasks.filter(\.isCompleted).count
        return Double(completed) / Double(allTasks.count)
    }

    var totalTaskCount: Int {
        milestones.reduce(0) { $0 + $1.dailyTasks.count }
    }

    var completedTaskCount: Int {
        milestones.reduce(0) { $0 + $1.dailyTasks.filter(\.isCompleted).count }
    }
}
