
import SwiftUI

// Education Level Section
struct EducationLevelSection: View {
    @ObservedObject var viewModel: QuestionSettingsViewModel
    
    var body: some View {
        Section("Education Level") {
            HStack(spacing: 12) {
                ForEach(EducationLevel.allCases, id: \.self) { level in
                    EducationLevelButton(
                        level: level,
                        isSelected: viewModel.educationLevel == level
                    ) {
                        viewModel.educationLevel = level
                    }
                }
            }
        }
    }
}
