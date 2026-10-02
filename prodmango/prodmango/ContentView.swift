import SwiftUI
import SwiftData

enum ActiveTab: String, CaseIterable, Identifiable {
    case focus = "Focus"
    case mango = "Mango"
    case settings = "Settings"
    
    
    var id: String { rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case mango = "Mango"
    case blue = "blueberry Blue"
    case green = "grape green"
    case purple = "plum Purple"
    case pink = "respberry red"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .mango: return .orange
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .pink: return .pink
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    
    @Query(
        filter: #Predicate<DailyTask> { task in
            task.isCompleted == false
        },
        sort: \DailyTask.createdAt
    ) private var todaysTasks: [DailyTask]
    
    @Query private var ambitions: [Ambition]
    
    @State private var activeTab: ActiveTab = .focus
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var dailySchedule = ""
    
    @AppStorage("APP_THEME") private var appTheme: AppTheme = .mango
    
    var body: some View {
        VStack(spacing: 0) {
            // Header & Tab Switcher
            HStack {
                Text("prodmango")
                    .font(.headline)
                
                Spacer()
                
                Picker("", selection: $activeTab) {
                    Text("Focus").tag(ActiveTab.focus)
                    Text("Mango").tag(ActiveTab.mango)
                    Image(systemName: "gearshape").tag(ActiveTab.settings) // New Settings Tab
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            .padding(10)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Body View
            if activeTab == .focus {
                focusView
            } else if activeTab == .mango {
                MangoView()
            } else {
                SettingsView()
            }
        }
        .frame(width: 380, height: 480)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown Error")
        }
        .tint(appTheme.color)
    }
    
    // MARK: - Focus (Daily Checklist) View
    @ViewBuilder
    private var focusView: some View {
        if todaysTasks.isEmpty {
            VStack {
                Spacer()
                ContentUnavailableView(
                    "No Tasks For Today",
                    systemImage: "sparkles",
                    description: Text(ambitions.isEmpty ? "Head to the Mango tab to set your ambitions first!" : "Ready for today's orders? Click Generate Plan.")
                )
                Spacer()
            }
        } else {
            List {
                ForEach(todaysTasks) { task in
                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            withAnimation {
                                task.toggleCompletion()
                            }
                        } label: {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.system(size: 13, weight: .medium))
                                .strikethrough(task.isCompleted)
                            
                            HStack {
                                if let time = task.timeEstimate, !time.isEmpty {
                                    Text(time)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.blue.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                }
                                
                                if !task.notes.isEmpty {
                                    Text(task.notes)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let ambitionName = task.ambition?.title {
                                Text(ambitionName)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        context.delete(todaysTasks[index])
                    }
                }
            }
            .listStyle(.plain)
        }
        
        // MARK: - Footer Layout
        VStack(spacing: 0) {
            Divider()
            
            if todaysTasks.isEmpty {
                TextField("How much time do you have today?", text: $dailySchedule)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
            }
            
            HStack {
                if !todaysTasks.isEmpty {
                    Button("Clear All") {
                        for task in todaysTasks {
                            context.delete(task)
                        }
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
                
                Spacer()
                
                Button(action: triggerAI) {
                    if isGenerating {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 6)
                    } else {
                        Label("Generate Plan", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isGenerating || ambitions.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(10)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - AI Action
    private func triggerAI() {
        isGenerating = true
        Task {
            do {
                _ = try await GoalEngine.shared.generateDailyTasks(for: ambitions, context: context, dailySchedule: dailySchedule)
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }
    
    struct SettingsView: View {
        @State private var apiKey: String = UserDefaults.standard.string(forKey: "OPENROUTER_API_KEY") ?? ""
        @State private var showSaved = false
        
        // NEW: This saves your color choice automatically
        @AppStorage("APP_THEME") private var appTheme: AppTheme = .mango
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.headline)
                
                // Appearance Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Accent Color")
                        Spacer()
                        Picker("", selection: $appTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                HStack {
                                    Circle()
                                        .fill(theme.color)
                                    Text(theme.rawValue)
                                }
                                .tag(theme)
                            }
                        }
                        .frame(width: 150)
                    }
                }
                
                Divider()
                
                // API Key Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenRouter API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SecureField("sk-or-v1-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Button("Save Key") {
                            UserDefaults.standard.set(apiKey, forKey: "OPENROUTER_API_KEY")
                            showSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSaved = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if showSaved {
                            Text("Successfully Saved!")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.leading, 8)
                        }
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}
