import SwiftUI

struct LearningSubjectSection: View {
    @StateObject private var subjectManager = SubjectManager.shared
    @Binding var selectedSubject: SubjectType
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(subjectManager.allSubjects, id: \.id) { subject in
                SubjectSelectionButton(
                    subject: subject,
                    isSelected: selectedSubject.id == subject.id
                ) {
                    withAnimation(.spring()) {
                        selectedSubject = subject
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
