import SwiftUI

struct StudyView: View {
    @StateObject private var studyViewModel: StudyViewModel
    let questions: [Question]
    
    init(questions: [Question], homeViewModel: HomeViewModel) {
        print("🎯 StudyView initialized with \(questions.count) questions")
        self.questions = questions
        let viewModel = StudyViewModel(homeViewModel: homeViewModel)
        _studyViewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            // Progress bar
            ProgressView(value: Double(min(studyViewModel.currentIndex + 1, studyViewModel.totalQuestions)),
                        total: Double(studyViewModel.totalQuestions))
                .progressViewStyle(.linear)
                .padding()
            
            Text("\(studyViewModel.currentIndex + 1) / \(studyViewModel.totalQuestions)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !studyViewModel.hasQuestions {
                Text("No questions available")
                    .font(.headline)
                    .foregroundColor(.gray)
            } else {
                if let currentQuestion = studyViewModel.currentQuestion {
                    VStack(alignment: .leading, spacing: 20) {
                        switch currentQuestion.type {
                        case .multipleChoice:
                            MultipleChoiceView(
                                question: currentQuestion,
                                selectedAnswer: $studyViewModel.selectedAnswer,
                                showExplanation: studyViewModel.showExplanation
                            )
                        case .fillInBlanks:
                            FillInBlanksView(
                                question: currentQuestion,
                                answer: $studyViewModel.selectedAnswer,
                                showExplanation: studyViewModel.showExplanation
                            )
                        case .matching:
                            MatchingView(
                                question: currentQuestion,
                                selectedPairs: $studyViewModel.matchingPairs,
                                showExplanation: studyViewModel.showExplanation
                            )
                        }
                        
                        if studyViewModel.showExplanation {
                            ExplanationView(question: currentQuestion)
                        }
                        
                        ActionButton(viewModel: studyViewModel)
                    }
                    .padding()
                    .id(currentQuestion.id)
                }
                
                Spacer()
            }
        }
        .onAppear {
            print("📝 StudyView appeared with \(questions.count) questions")
            // 지연 로드로 변경
            DispatchQueue.main.async {
                studyViewModel.loadQuestions(questions)
            }
        }
        .id("\(questions.hashValue)")  // View 강제 갱신을 위한 id 추가
    }
}

private struct ExplanationView: View {
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explanation")
                .font(.headline)
            Text(question.explanation)
                .font(.body)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct ActionButton: View {
    @ObservedObject var viewModel: StudyViewModel
    
    var body: some View {
        Button(action: {
            if viewModel.showExplanation {
                if viewModel.isLastQuestion {
                    viewModel.saveProgress()
                } else {
                    viewModel.nextQuestion()
                }
            } else {
                viewModel.submitAnswer()
            }
        }) {
            Text(viewModel.showExplanation ?
                 (viewModel.isLastQuestion ? "Finish" : "Next Question") :
                    "Submit Answer")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSubmit ? Color.accentColor : Color.gray)
                .cornerRadius(10)
        }
        .disabled(!viewModel.canSubmit)
        .padding()
    }
}
