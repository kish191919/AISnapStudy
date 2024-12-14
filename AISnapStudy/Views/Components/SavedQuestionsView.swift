import SwiftUI

struct SavedQuestionsView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Binding var selectedTab: Int
    @State private var selectedQuestions: Set<String> = []
    @State private var showCreateSetDialog = false
    @State private var setName = "Saved Questions Set"
    @State private var selectedSubject: DefaultSubject = .generalKnowledge

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
        .sheet(isPresented: $showCreateSetDialog) {  // alert 대신 sheet 사용
            CreateSetView(
                setName: $setName,
                selectedSubject: $selectedSubject,
                onCreate: {
                    createNewSet()
                    showCreateSetDialog = false
                }
            )
        }
    }

    private func createNewSet() {
        // 선택된 질문들의 ID 리스트
        let selectedQuestionIds = selectedQuestions

        let selectedQuestionsList = homeViewModel.savedQuestions
            .filter { selectedQuestions.contains($0.id) }
            .map { question in
                Question(
                    id: UUID().uuidString,
                    type: question.type,
                    subject: selectedSubject,
                    question: question.question,
                    options: question.options,
                    correctAnswer: question.correctAnswer,
                    explanation: question.explanation,
                    hint: question.hint,
                    isSaved: false,  // 새 질문은 북마크 해제된 상태로 생성
                    createdAt: Date()
                )
            }
        
        let newProblemSet = ProblemSet(
            subject: selectedSubject,
            subjectType: "default",
            subjectId: selectedSubject.rawValue,
            subjectName: selectedSubject.displayName,
            questions: selectedQuestionsList,
            educationLevel: .elementary,
            name: setName
        )

        Task {
            // 먼저 새 문제 세트 저장
            await homeViewModel.saveProblemSet(newProblemSet)
            await homeViewModel.setSelectedProblemSet(newProblemSet)
            
            // 선택된 원본 질문들의 북마크 해제
            for questionId in selectedQuestionIds {
                if let originalQuestion = homeViewModel.savedQuestions.first(where: { $0.id == questionId }) {
                    await homeViewModel.toggleQuestionBookmark(originalQuestion)
                }
            }
            
            selectedTab = 1
            showCreateSetDialog = false
            selectedQuestions.removeAll()
        }
    }
}

// 새로운 CreateSetView 구현
struct CreateSetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var setName: String
    @Binding var selectedSubject: DefaultSubject
    let onCreate: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set Name")) {
                    TextField("Enter set name", text: $setName)
                }
                
                Section(header: Text("Subject")) {
                    Picker("Select Subject", selection: $selectedSubject) {
                        ForEach(DefaultSubject.allCases, id: \.self) { subject in
                            Text(subject.displayName)
                                .tag(subject)
                        }
                    }
                }
            }
            .navigationTitle("Create New Set")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Create") {
                    onCreate()
                }
            )
        }
    }
}

private struct CreateSetAlert: View {
    @Binding var setName: String
    @Binding var selectedSubject: DefaultSubject
    let onCreate: () -> Void

    var body: some View {
        Group {
            TextField("Set Name", text: $setName)
            
            Picker("Subject", selection: $selectedSubject) {
                ForEach(DefaultSubject.allCases, id: \.self) { subject in
                    Text(subject.displayName)
                        .tag(subject)
                }
            }
            
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                onCreate()
            }
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
