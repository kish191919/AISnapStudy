import SwiftUI

struct SavedQuestionsView: View {
    let questions: [Question]
    let homeViewModel: HomeViewModel
    @State private var showStudyView = false
    
    var body: some View {
        List(questions) { question in
            SavedQuestionCard(question: question)
                .onTapGesture {
                    let problemSet = ProblemSet(
                        id: UUID().uuidString,
                        subject: question.subject,
                        subjectType: "default",  // 저장된 문제는 항상 기본 과목으로 처리
                        subjectId: question.subject.rawValue,
                        subjectName: question.subject.displayName,
                        questions: [question],
                        createdAt: Date(),
                        educationLevel: .elementary,
                        name: "Saved Question"
                    )
                    homeViewModel.setSelectedProblemSet(problemSet)
                    showStudyView = true
                }
        }
        .navigationTitle("Saved Questions")
        .background(
            NavigationLink(
                isActive: $showStudyView,
                destination: {
                    if let studyViewModel = homeViewModel.studyViewModel {
                        StudyView(
                            questions: [questions[0]],
                            studyViewModel: studyViewModel,
                            selectedTab: .constant(1)
                        )
                    }
                },
                label: { EmptyView() }
            )
        )
    }
}
