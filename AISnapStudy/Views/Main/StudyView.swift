
import SwiftUI
import CoreData

struct StudyView: View {
    
    @Environment(\.managedObjectContext) private var context
    @Binding var selectedTab: Int
    @ObservedObject var studyViewModel: StudyViewModel  // StateObject 대신 ObservedObject 사용
    let questions: [Question]
    

    @State private var showExplanation: Bool = false
    @State private var isCorrect: Bool? = nil
    

    
    init(questions: [Question],
         studyViewModel: StudyViewModel,  // 변경된 부분
         selectedTab: Binding<Int>) {
        self.questions = questions
        self._selectedTab = selectedTab
        self.studyViewModel = studyViewModel  // 외부에서 주입받은 ViewModel 사용
    }
    
    var body: some View {
        VStack {
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let currentQuestion = studyViewModel.currentQuestion {
                            
                            switch currentQuestion.type {
                            case .multipleChoice:
                                MultipleChoiceView(
                                    question: currentQuestion,
                                    selectedAnswer: $studyViewModel.selectedAnswer,
                                    showExplanation: studyViewModel.showExplanation,
                                    isCorrect: isCorrect
                                )
                                
                                if showExplanation && studyViewModel.showExplanation {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(currentQuestion.explanation)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .padding()
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(10)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                                
                            case .fillInBlanks:
                                FillInBlanksView(
                                    question: currentQuestion,
                                    answer: $studyViewModel.selectedAnswer,
                                    showExplanation: studyViewModel.showExplanation,
                                    isCorrect: isCorrect
                                )
                                
                            case .matching:
                                MatchingView(
                                    question: currentQuestion,
                                    selectedPairs: $studyViewModel.matchingPairs,
                                    showExplanation: studyViewModel.showExplanation,
                                    isCorrect: isCorrect
                                )
                                
                            case .trueFalse:
                                TrueFalseView(
                                    question: currentQuestion,
                                    selectedAnswer: $studyViewModel.selectedAnswer,
                                    showExplanation: studyViewModel.showExplanation,
                                    isCorrect: isCorrect
                                )
                            }
                        }
                    }
                    .padding()
                }
                
                // Action Buttons
                VStack {
                    Divider()
                    
                    HStack(spacing: 12) {
                        if studyViewModel.showExplanation {
                            Button(action: {
                                withAnimation {
                                    showExplanation.toggle()
                                }
                            }) {
                                Image(systemName: showExplanation ? "lightbulb.fill" : "lightbulb")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 24))
                                    .padding(8)
                                    .background(Circle().fill(Color.yellow.opacity(0.2)))
                            }
                        }
                        
                        ActionButton(
                            viewModel: studyViewModel,
                            selectedTab: $selectedTab,
                            isCorrect: $isCorrect,
                            showExplanation: $showExplanation
                        )
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                }
            }
        }
        
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
    @Binding var selectedTab: Int
    @Binding var isCorrect: Bool?
    @Binding var showExplanation: Bool
    
    var body: some View {
        Button(action: {
            if viewModel.showExplanation {
                if viewModel.isLastQuestion {
                    viewModel.saveProgress()
                    selectedTab = 3
                } else {
                    viewModel.nextQuestion()
                    isCorrect = nil
                    showExplanation = false
                }
            } else {
                viewModel.submitAnswer()
                isCorrect = viewModel.selectedAnswer == viewModel.currentQuestion?.correctAnswer
            }
        }) {
            Text(viewModel.showExplanation ?
                 (viewModel.isLastQuestion ? "Finish" : "Next Question") :
                    "Submit Answer")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(10)
        }
        .disabled(!viewModel.canSubmit)
    }
}
