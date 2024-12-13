import SwiftUI

struct SavedQuestionsView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Binding var selectedTab: Int
    @State private var selectedQuestions: Set<String> = []
    @State private var showCreateSetDialog = false
    @State private var setName = "Saved Questions Set"

    var body: some View {
        VStack {
            if homeViewModel.savedQuestions.isEmpty {
                EmptyStateView()
            } else {
                SavedQuestionsList(
                    questions: homeViewModel.savedQuestions,
                    selectedQuestions: $selectedQuestions,
                    homeViewModel: homeViewModel
                )
            }

            if !selectedQuestions.isEmpty {
                CreateSetButton(
                    count: selectedQuestions.count,
                    action: { showCreateSetDialog = true }
                )
            }
        }
        .navigationTitle("Saved Questions")
        .alert("Create New Set", isPresented: $showCreateSetDialog) {
            CreateSetAlert(
                setName: $setName,
                onCreate: createNewSet
            )
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

// MARK: - Supporting Views
private struct EmptyStateView: View {
    var body: some View {
        Text("No saved questions")
            .foregroundColor(.secondary)
    }
}

private struct SavedQuestionsList: View {
    let questions: [Question]
    @Binding var selectedQuestions: Set<String>
    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        List {
            ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                SavedQuestionCard(
                    question: question,
                    isSelected: selectedQuestions.contains(question.id)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleSelection(for: question)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    UnsaveButton(question: question, homeViewModel: homeViewModel)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    UnsaveButton(question: question, homeViewModel: homeViewModel, tint: .blue)
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    private func toggleSelection(for question: Question) {
        if selectedQuestions.contains(question.id) {
            selectedQuestions.remove(question.id)
        } else {
            selectedQuestions.insert(question.id)
        }
    }
}

private struct UnsaveButton: View {
    let question: Question
    let homeViewModel: HomeViewModel
    var tint: Color? = nil

    var body: some View {
        Button {
            Task {
                await homeViewModel.toggleQuestionBookmark(question)
                HapticManager.shared.impact(style: .medium)
            }
        } label: {
            Label("Unsave", systemImage: "bookmark.slash.fill")
        }
        .tint(tint)
    }
}

private struct CreateSetButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Create New Set (\(count))")
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

private struct CreateSetAlert: View {
    @Binding var setName: String
    let onCreate: () -> Void

    var body: some View {
        Group {
            TextField("Set Name", text: $setName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                onCreate()
            }
        }
    }
}
