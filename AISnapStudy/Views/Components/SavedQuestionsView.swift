import SwiftUI

struct SavedQuestionsView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Binding var selectedTab: Int
    @State private var selectedQuestions: Set<String> = []
    @State private var showCreateSetDialog = false
    @State private var setName = "Saved Questions Set" // 추가

    var body: some View {
        VStack {
            if homeViewModel.savedQuestions.isEmpty {
                Text("No saved questions")
                    .foregroundColor(.secondary)
            } else {
                List {
                    // 배열의 인덱스를 id로 사용
                    ForEach(Array(homeViewModel.savedQuestions.enumerated()), id: \.offset) { index, question in
                        SavedQuestionCard(
                            question: question,
                            isSelected: selectedQuestions.contains(question.id)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedQuestions.contains(question.id) {
                                selectedQuestions.remove(question.id)
                            } else {
                                selectedQuestions.insert(question.id)
                            }
                        }
                    }
                }
            }

            if !selectedQuestions.isEmpty {
                Button(action: {
                    showCreateSetDialog = true
                }) {
                    Text("Create New Set (\(selectedQuestions.count))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .navigationTitle("Saved Questions")
        .alert("Create New Set", isPresented: $showCreateSetDialog) {
            TextField("Set Name", text: $setName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                createNewSet()
            }
        } message: {
            Text("Enter a name for your question set")
        }
    }

    private func createNewSet() {
        // 선택된 질문들의 복사본 생성
        let selectedQuestionsList = homeViewModel.savedQuestions
            .filter { selectedQuestions.contains($0.id) }
            .map { question in
                // 새로운 Question 인스턴스 생성
                Question(
                    id: UUID().uuidString,  // 새로운 ID 부여
                    type: question.type,
                    subject: question.subject,
                    question: question.question,
                    options: question.options,
                    correctAnswer: question.correctAnswer,
                    explanation: question.explanation,
                    hint: question.hint,
                    isSaved: false,  // 북마크 상태는 false로 시작
                    createdAt: Date()
                )
            }
        
        let newProblemSet = ProblemSet(
            subject: DefaultSubject.generalKnowledge,
            subjectType: "default",
            subjectId: DefaultSubject.generalKnowledge.rawValue,
            subjectName: "Saved Questions",
            questions: selectedQuestionsList,  // 복사된 질문들 사용
            educationLevel: .elementary,
            name: setName
        )

        Task {
            await homeViewModel.saveProblemSet(newProblemSet)
            await homeViewModel.setSelectedProblemSet(newProblemSet)
            selectedTab = 1
            showCreateSetDialog = false
            selectedQuestions.removeAll()
        }
    }
}
