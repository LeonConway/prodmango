import SwiftUI
import SwiftData

struct MangoView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Ambition.createdAt, order: .reverse) private var ambitions: [Ambition]
    
    @State private var showingNewAmbitionSheet = false
    @State private var selectedAmbitionForMilestone: Ambition?
    
    var body: some View {
        ZStack {
            // MARK: - Main Content
            VStack(spacing: 0) {
                if ambitions.isEmpty {
                    ContentUnavailableView(
                        "No Ambitions Yet",
                        systemImage: "leaf",
                        description: Text("Add your core goals to fuel the daily engine.")
                    )
                } else {
                    List {
                        ForEach(ambitions) { ambition in
                            Section {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(ambition.title).font(.headline)
                                        Spacer()
                                        Text("\(Int(ambition.progress * 100))%")
                                            .font(.caption.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.15))
                                            .clipShape(Capsule())
                                        
                                        Button(role: .destructive) {
                                                context.delete(ambition)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red.opacity(0.7))
                                            }
                                            .buttonStyle(.plain)
                                            .padding(.leading, 6)
                                    }
                                    if !ambition.details.isEmpty {
                                        Text(ambition.details).font(.caption).foregroundColor(.secondary)
                                    }
                                    ProgressView(value: ambition.progress).progressViewStyle(.linear)
                                }
                                .padding(.vertical, 4)
                                
                                ForEach(ambition.milestones) { milestone in
                                    HStack {
                                        Button {
                                            milestone.isCompleted.toggle()
                                        } label: {
                                            Image(systemName: milestone.isCompleted ? "checkmark.square.fill" : "square")
                                                .foregroundColor(milestone.isCompleted ? .green : .secondary)
                                        }.buttonStyle(.plain)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(milestone.title)
                                                .font(.system(size: 13, weight: .medium))
                                                .strikethrough(milestone.isCompleted)
                                            Text("Due: \(milestone.endDate.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.system(size: 10)).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.leading, 12)
                                }
                                .onDelete { indexSet in
                                    for index in indexSet { context.delete(ambition.milestones[index]) }
                                }
                                
                                Button {
                                    selectedAmbitionForMilestone = ambition
                                } label: {
                                    Label("Add Milestone", systemImage: "plus").font(.caption)
                                }.buttonStyle(.borderless).padding(.leading, 12)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet { context.delete(ambitions[index]) }
                        }
                    }
                    .listStyle(.inset)
                }
                
                Divider()
                
                HStack {
                    Text("\(ambitions.count) Ambitions Active").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button {
                        showingNewAmbitionSheet = true
                    } label: {
                        Label("New Ambition", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(10)
                .background(Color(nsColor: .windowBackgroundColor))
            }
            
            // MARK: - Custom Overlays (Fixes the crash bug!)
            
            if showingNewAmbitionSheet {
                Color.black.opacity(0.4).ignoresSafeArea()
                NewAmbitionSheet(isPresented: $showingNewAmbitionSheet)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(radius: 20)
                    .padding(20)
            }
            
            if let ambition = selectedAmbitionForMilestone {
                Color.black.opacity(0.4).ignoresSafeArea()
                NewMilestoneSheet(ambition: ambition, selectedAmbition: $selectedAmbitionForMilestone)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(radius: 20)
                    .padding(20)
            }
        }
    }
}

// MARK: - Refactored Overlays

// MARK: - New Ambition Sheet
struct NewAmbitionSheet: View {
    @Environment(\.modelContext) private var context
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var situation = ""
    @State private var constraints = ""
    @State private var notes = ""
    @State private var hasTargetDate = false
    @State private var targetDate = Date().addingTimeInterval(86400 * 30)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Ambition")
                .font(.headline)
            
            // 1. The Main Goal
            VStack(alignment: .leading, spacing: 4) {
                Text("What is the goal?").font(.caption).bold()
                TextField("e.g. Build a $10k/mo Micro SaaS", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            // 2. The Situation
            VStack(alignment: .leading, spacing: 4) {
                Text("What is your current situation?").font(.caption).bold()
                TextField("e.g. I work a 9-5 and have basic coding skills...", text: $situation, axis: .vertical)
                    .lineLimit(2...3)
                    .textFieldStyle(.roundedBorder)
            }
            
            // 3. The Limits
            VStack(alignment: .leading, spacing: 4) {
                Text("What are your limits? (Time/Money)").font(.caption).bold()
                TextField("e.g. I only have 1 hour a day and zero budget...", text: $constraints, axis: .vertical)
                    .lineLimit(2...3)
                    .textFieldStyle(.roundedBorder)
            }
            
            // 4. Target Date
            Toggle("Set Target Date", isOn: $hasTargetDate)
            if hasTargetDate {
                DatePicker("Target", selection: $targetDate, displayedComponents: .date)
            }
            
            HStack {
                Button("Cancel") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create Ambition") {
                    // Combine the answers neatly for the AI
                    var compiledDetails = ""
                    if !situation.isEmpty { compiledDetails += "Context: \(situation)\n" }
                    if !constraints.isEmpty { compiledDetails += "Constraints: \(constraints)\n" }
                    if !notes.isEmpty { compiledDetails += "Notes: \(notes)" }
                    
                    let ambition = Ambition(
                        title: title,
                        details: compiledDetails.trimmingCharacters(in: .whitespacesAndNewlines),
                        targetDate: hasTargetDate ? targetDate : nil
                    )
                    context.insert(ambition)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 350)
    }
}

struct NewMilestoneSheet: View {
    @Environment(\.modelContext) private var context
    let ambition: Ambition
    @Binding var selectedAmbition: Ambition?
    
    @State private var title = ""
    @State private var details = ""
    @State private var endDate = Date().addingTimeInterval(86400 * 14)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Milestone").font(.headline)
            Text("For: \(ambition.title)").font(.caption).foregroundColor(.secondary)
            
            TextField("e.g. Launch landing page", text: $title)
                .textFieldStyle(.roundedBorder)
            
            DatePicker("Deadline", selection: $endDate, displayedComponents: .date)
            
            HStack {
                Button("Cancel") { selectedAmbition = nil }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add Milestone") {
                    let milestone = Milestone(title: title, details: details, startDate: .now, endDate: endDate, ambition: ambition)
                    ambition.milestones.append(milestone)
                    context.insert(milestone)
                    selectedAmbition = nil
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}
