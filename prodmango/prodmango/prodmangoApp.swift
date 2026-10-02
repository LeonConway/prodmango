import SwiftUI
import SwiftData // 1. Make sure to import SwiftData

@main
struct testmangoApp: App {
    var body: some Scene {
        MenuBarExtra("prodmango", systemImage: "target") {
            ContentView()
                // 2. THIS IS THE MAGIC LINE: It creates the database for your 3 models
                .modelContainer(for: [Ambition.self, Milestone.self, DailyTask.self])
        }
        .menuBarExtraStyle(.window)
    }
}
