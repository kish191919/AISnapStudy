import SwiftUI

// Difficulty Section
struct DifficultySection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
        Section("Difficulty Level") {
            Picker("Difficulty", selection: $viewModel.difficulty) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.rawValue.capitalized)
                        .tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

