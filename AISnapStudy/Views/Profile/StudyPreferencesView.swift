// Views/Profile/StudyPreferencesView.swift

import SwiftUI

struct StudyPreferencesView: View {
    @StateObject private var viewModel = StudyPreferencesViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Daily Goals")) {
                Stepper("Questions per day: \(viewModel.dailyGoal)",
                        value: $viewModel.dailyGoal, in: 1...20)
            }
            
            Section(header: Text("Preferred Difficulty")) {
                Picker("Default Difficulty", selection: $viewModel.preferredDifficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.displayName)
                            .tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text("Study Reminders")) {
                Toggle("Daily Reminder", isOn: $viewModel.dailyReminder)
                if viewModel.dailyReminder {
                    DatePicker("Reminder Time",
                              selection: $viewModel.reminderTime,
                              displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("Study Preferences")
    }
}

class StudyPreferencesViewModel: ObservableObject {
    @Published var dailyGoal: Int = UserDefaults.standard.integer(forKey: "dailyGoal") {
        didSet {
            UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
        }
    }
    
    @Published var preferredDifficulty: Difficulty = Difficulty(rawValue:
        UserDefaults.standard.string(forKey: "preferredDifficulty") ?? "medium"
    ) ?? .medium {
        didSet {
            UserDefaults.standard.set(preferredDifficulty.rawValue, forKey: "preferredDifficulty")
        }
    }
    
    @Published var dailyReminder: Bool = UserDefaults.standard.bool(forKey: "dailyReminder") {
        didSet {
            UserDefaults.standard.set(dailyReminder, forKey: "dailyReminder")
        }
    }
    
    @Published var reminderTime: Date = Date(timeIntervalSince1970:
        UserDefaults.standard.double(forKey: "reminderTime")
    ) {
        didSet {
            UserDefaults.standard.set(reminderTime.timeIntervalSince1970, forKey: "reminderTime")
        }
    }
}

