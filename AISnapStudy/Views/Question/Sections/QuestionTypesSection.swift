
import SwiftUI

// Question Type Section
struct QuestionTypesSection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
        Section("Type") {
            VStack(spacing: 10) {
                QuestionTypeCounter(
                    title: "Multiple",
                    count: $viewModel.multipleChoiceCount
                )
                
                QuestionTypeCounter(
                    title: "True/False",
                    count: $viewModel.trueFalseCount
                )
                
            }
        }
    }
}
