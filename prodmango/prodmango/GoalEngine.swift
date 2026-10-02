//
//  GoalEngine.swift
//  prodmango
//
//  Created by Leon Conway on 24/08/2026.
//
import Foundation
import SwiftData


// MARK: - AI Response Data Transfer Objects (DTOs)
struct DailyPlanResponse: Codable {
    let tasks: [TaskPayload]
    
    struct TaskPayload: Codable {
        let title: String
        let notes: String
        let milestoneId: UUID
        let timeEstimate: String
    }
}

// MARK: - Goal Engine Service
@MainActor
final class GoalEngine {
    static let shared = GoalEngine()
    
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    
    // Replace with your API key or fetch it securely from Keychain / UserDefaults
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "OPENROUTER_API_KEY") ?? ""
    }
    

    private init() {}

    // MARK: - Public API Call
    /// Analyzes all active ambitions and generates today's actionable daily tasks in SwiftData.
    func generateDailyTasks(
        for ambitions: [Ambition],
        context: ModelContext,
        dailySchedule: String
    ) async throws -> [DailyTask] {
        
        let activeAmbitions = ambitions.filter { !$0.isArchived }
        guard !activeAmbitions.isEmpty else {
            throw GoalEngineError.noActiveAmbitions
        }

        // 1. Build context strings of ambitions and their underlying milestones
        var contextDescription = ""
                var milestoneLookup: [UUID: Milestone] = [:]

                for ambition in activeAmbitions {
                    contextDescription += "\nAmbition: \(ambition.title)"
                    if !ambition.details.isEmpty {
                        contextDescription += " (Context: \(ambition.details))"
                    }
                    contextDescription += "\nMilestones:"
                    
                    for milestone in ambition.milestones where !milestone.isCompleted {
                        milestoneLookup[milestone.id] = milestone
                        contextDescription += "\n - [ID: \(milestone.id.uuidString)] \(milestone.title) (Deadline: \(milestone.endDate.formatted(date: .abbreviated, time: .omitted)))"
                        
                        // NEW: Fetch completed tasks for this milestone to give the AI memory
                        let completedTasks = milestone.dailyTasks.filter { $0.isCompleted }
                        if !completedTasks.isEmpty {
                            // Get the 5 most recently completed tasks
                            let recentCompleted = completedTasks.sorted { $0.createdAt > $1.createdAt }.prefix(5)
                            contextDescription += "\n   > ALREADY COMPLETED (Do not suggest these):"
                            for task in recentCompleted {
                                contextDescription += "\n     * \(task.title)"
                            }
                        }
                    }
                }
            guard !milestoneLookup.isEmpty else {
            throw GoalEngineError.noActiveMilestones
        }

        // 2. Prepare the prompt payload
        let systemPrompt = """
        You are an elite, hyper-specific executive coach. 
        Your goal is to break down long-term ambitions into high-leverage micro-actions for today.
        
        Rules:
        1. Select 2 to 5 critical actions to perform TODAY.
        2. The user will provide their schedule/capacity for today. You MUST ensure the combined time estimates of your tasks realistically fit within their available time.
        3. Provide a concise `timeEstimate` for each task (e.g., "15m", "1h").
        4. Output MUST be valid JSON adhering strictly to the required schema.
        5. CRITICAL: Review the "ALREADY COMPLETED" lists. Do NOT suggest tasks the user has already done.
        """

        let userPrompt = """
        Today's Schedule / Capacity: \(dailySchedule.isEmpty ? "Normal day, standard capacity." : dailySchedule)

        Here is the user's current goal hierarchy:
        \(contextDescription)

        Generate today's focus tasks in JSON format:
        {
          "tasks": [
            {
              "title": "Task title",
              "notes": "Specific details or next steps",
              "milestoneId": "UUID-STRING-HERE",
              "timeEstimate": "e.g. 30m"
            }
          ]
        }
        """

        // 3. Make the Network Request
        let response = try await sendOpenAIRequest(systemPrompt: systemPrompt, userPrompt: userPrompt)
        
        // 4. Map the response directly into SwiftData objects
        var createdTasks: [DailyTask] = []
        let today = Calendar.current.startOfDay(for: .now)

        for payload in response.tasks {
            guard let parentMilestone = milestoneLookup[payload.milestoneId] else {
                continue
            }
            
            let newTask = DailyTask(
                title: payload.title,
                notes: payload.notes,
                date: today,
                milestone: parentMilestone,
                timeEstimate: payload.timeEstimate
            )
            
            context.insert(newTask)
            createdTasks.append(newTask)
        }

        try context.save()
        return createdTasks
    }

    // MARK: - Network Request Helper
    private func sendOpenAIRequest(systemPrompt: String, userPrompt: String) async throws -> DailyPlanResponse {
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("YourAppSiteURL", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("AmbitionApp", forHTTPHeaderField: "X-Title")

        // Change the model string to use OpenRouter's routing format (e.g., openai/, anthropic/)
        let requestBody: [String: Any] = [
            "model": "openai/gpt-4o-mini", // Or "anthropic/claude-3-5-sonnet", etc.
            "response_format": ["type": "json_object"],
            "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": userPrompt]
                        ],
        
            "temperature": 0.4
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoalEngineError.apiError(message: errorText)
        }

        // Parse OpenAI Chat Completion wrapper
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8) else {
            throw GoalEngineError.parsingError
        }

        return try JSONDecoder().decode(DailyPlanResponse.self, from: contentData)
    }
}

// MARK: - Engine Errors
enum GoalEngineError: LocalizedError {
    case noActiveAmbitions
    case noActiveMilestones
    case apiError(message: String)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .noActiveAmbitions:
            return "No active ambitions found. Add an ambition before generating tasks."
        case .noActiveMilestones:
            return "No active milestones found for your ambitions."
        case .apiError(let message):
            return "API Error: \(message)"
        case .parsingError:
            return "Failed to parse the AI response."
        }
    }
}
