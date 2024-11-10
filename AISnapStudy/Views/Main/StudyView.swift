//  Views/Main/StudyView.swift

import SwiftUI

struct StudyView: View {
    @State private var showExplanation = false
    @State private var isCorrect: Bool? = nil // Store answer correctness
    @State private var selectedAnswer: String? = nil // Track selected answer
    @State private var questionIndex = 0 // Current question index
    
    var questions: [Question] // Array of questions to display
    
    // Initializer to receive questions array
    init(questions: [Question]) {
        self.questions = questions
    }

    var body: some View {
        VStack {
            // Progress bar to show current question progress
            ProgressView(value: Double(min(questionIndex + 1, questions.count)), total: Double(questions.count))
                .progressViewStyle(LinearProgressViewStyle())
                .padding()
            
            if questions.isEmpty {
                Text("No questions available")
                    .font(.headline)
                    .foregroundColor(.gray)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    if questionIndex < questions.count {
                        QuestionCardView(
                            question: questions[questionIndex],
                            selectedAnswer: $selectedAnswer,
                            isCorrect: $isCorrect,
                            onAnswerSelected: handleAnswerSelected
                        )
                        
                        if let isCorrect = isCorrect {
                            Text(isCorrect ? "Correct!" : "Wrong!")
                                .foregroundColor(isCorrect ? .green : .red)
                                .font(.headline)
                                .padding()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    // Handle answer selection and move to next question after a delay
    private func handleAnswerSelected(isCorrect: Bool) {
        self.isCorrect = isCorrect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Wait 1 second before moving
            nextQuestion()
        }
    }
    
    private func nextQuestion() {
        guard questionIndex < questions.count - 1 else {
            return
        }
        questionIndex += 1
        resetAnswer()
    }
    
    private func resetAnswer() {
        isCorrect = nil
        selectedAnswer = nil
    }
}






struct StudyContentView: View {
    let problemSet: ProblemSet
    @ObservedObject var viewModel: StudyViewModel
    
    private var progress: Double {
        // 문제가 없을 경우 0을 반환
        guard viewModel.totalQuestions > 0 else { return 0 }
        // currentIndex는 0-based이므로 1을 더하고, total로 나누어 비율 계산
        return Double(min(viewModel.currentIndex + 1, viewModel.totalQuestions)) / Double(viewModel.totalQuestions)
    }
    
    var body: some View {
        VStack {
            // Progress Indicator - 수정된 부분
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .padding()
            
            Text("\(viewModel.currentIndex + 1) / \(viewModel.totalQuestions)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let question = viewModel.currentQuestion {
                VStack {
                    switch question.type {
                    case .multipleChoice:
                        MultipleChoiceView(
                            question: question,
                            selectedAnswer: $viewModel.selectedAnswer,
                            showExplanation: viewModel.showExplanation
                        )
                        
                    case .fillInBlanks:
                        FillInBlanksView(
                            question: question,
                            answer: $viewModel.selectedAnswer,
                            showExplanation: viewModel.showExplanation
                        )
                        
                    case .matching:
                        MatchingView(
                            question: question,
                            selectedPairs: $viewModel.matchingPairs,
                            showExplanation: viewModel.showExplanation
                        )
                    }
                }
                .id(question.id)
            }
        }
    }
}



struct QuestionView: View {
    let question: Question
    @ObservedObject var viewModel: StudyViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                let _ = debugLog("📖 Rendering question: \(question.question)")
                
                Text(question.question)
                    .font(.headline)
                    .padding()
                
                switch question.type {
                case .multipleChoice:
                    let _ = debugLog("🔤 Rendering MultipleChoiceView")
                    MultipleChoiceView(
                        question: question,
                        selectedAnswer: $viewModel.selectedAnswer,
                        showExplanation: viewModel.showExplanation
                    )
                case .fillInBlanks:
                    let _ = debugLog("✏️ Rendering FillInBlanksView")
                    FillInBlanksView(
                        question: question,
                        answer: $viewModel.selectedAnswer,
                        showExplanation: viewModel.showExplanation
                    )
                case .matching:
                    let _ = debugLog("🔄 Rendering MatchingView")
                    MatchingView(
                        question: question,
                        selectedPairs: $viewModel.matchingPairs,
                        showExplanation: viewModel.showExplanation
                    )
                }
                
                if viewModel.showExplanation {
                    ExplanationView(question: question)
                }
                
                ActionButton(viewModel: viewModel)
            }
            .padding()
        }
    }
    
    private func debugLog(_ message: String) {
        #if DEBUG
        print(message)
        #endif
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
