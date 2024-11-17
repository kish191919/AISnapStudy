import SwiftUI
import CoreData

struct StudyView: View {
   @Environment(\.managedObjectContext) private var context
   @Binding var selectedTab: Int
   @ObservedObject var studyViewModel: StudyViewModel
   let questions: [Question]
   
   @State private var showExplanation: Bool = false
    @State private var isCorrect: Bool? = nil  // 이 부분이 중요합니다
   @State private var isSaved: Bool = false
   @State private var previewSelectedAnswer: String? = nil  // 추가
   @State private var previewIsCorrect: Bool? = nil        // 추가
   
   init(questions: [Question],
        studyViewModel: StudyViewModel,
        selectedTab: Binding<Int>) {
       self.questions = questions
       self._selectedTab = selectedTab
       self.studyViewModel = studyViewModel
   }
   
    var body: some View {
        VStack {
            if studyViewModel.isGeneratingQuestions {
                VStack(spacing: 16) {
                    ProgressView(value: Double(studyViewModel.generatedQuestionCount),
                               total: Double(studyViewModel.totalExpectedQuestions)) {
                        Text("Generating Questions...")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .progressViewStyle(.linear)
                    .padding()
                    
                    Text("\(studyViewModel.generatedQuestionCount) / \(studyViewModel.totalExpectedQuestions)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    if !studyViewModel.generatedQuestions.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(studyViewModel.generatedQuestions) { question in
                                    QuestionPreviewCard(
                                        question: question,
                                        selectedAnswer: $previewSelectedAnswer,
                                        isCorrect: $previewIsCorrect,
                                        onAnswerSelected: { correct in
                                            print("Answer selected: \(correct)")
                                        }
                                    )
                                    .transition(.slide)
                                }
                            }
                            .padding()
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                        .frame(height: 20)
                    
                    ProgressView(value: Double(min(studyViewModel.currentIndex + 1, studyViewModel.totalQuestions)),
                               total: Double(studyViewModel.totalQuestions))
                        .progressViewStyle(CustomProgressViewStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    
                    Text("\(studyViewModel.currentIndex + 1) / \(studyViewModel.totalQuestions)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    if !studyViewModel.hasQuestions {
                        Text("No questions available")
                            .font(.title3)
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
                                        
                                    case .trueFalse:
                                        TrueFalseView(
                                            question: currentQuestion,
                                            selectedAnswer: $studyViewModel.selectedAnswer,
                                            showExplanation: studyViewModel.showExplanation,
                                            isCorrect: isCorrect  // 여기 isCorrect 바인딩이 문제일 수 있습니다
                                        )
                                    }
                                    
                                    if showExplanation && studyViewModel.showExplanation {
                                        ExplanationView(explanation: currentQuestion.explanation)
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        VStack {
                            Divider()
                            
                            HStack(spacing: 12) {
                                if studyViewModel.showExplanation {
                                    UtilityButtons(
                                        showExplanation: $showExplanation,
                                        isSaved: $isSaved,
                                        studyViewModel: studyViewModel
                                    )
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
        .onAppear {
            if let currentQuestion = studyViewModel.currentQuestion {
                isSaved = currentQuestion.isSaved
            }
        }
        .onChange(of: studyViewModel.currentQuestion) { newQuestion in
            if let question = newQuestion {
                isSaved = question.isSaved
            }
        }
    }
}

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * geometry.size.width,
                           height: 12)
            }
        }
        .frame(height: 12)
    }
}

// 새로 추가된 미리보기 카드 뷰
struct QuestionPreviewCard: View {
  let question: Question
  @Binding var selectedAnswer: String?
  @Binding var isCorrect: Bool?
  var onAnswerSelected: (Bool) -> Void
  
  var body: some View {
      VStack(alignment: .leading, spacing: 16) {
          // 상단 정보
          HStack {
              Text(question.type.rawValue.capitalized)
                  .font(.caption)
                  .padding(4)
                  .background(Color.blue.opacity(0.1))
                  .cornerRadius(4)
              
              Spacer()
              
              Text(question.difficulty.rawValue.capitalized)
                  .font(.caption)
                  .foregroundColor(.secondary)
          }
          
          // 질문
          Text(question.question)
              .font(.title3)
              .fontWeight(.semibold)
              .padding(.vertical, 4)
          
          // 답변 옵션
          ForEach(question.options, id: \.self) { option in
              Button(action: {
                  selectedAnswer = option
                  let correct = checkAnswer(option)
                  isCorrect = correct
                  onAnswerSelected(correct)
              }) {
                  HStack {
                      Text(option)
                      Spacer()
                      if selectedAnswer == option {
                          Image(systemName: isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                              .foregroundColor(isCorrect == true ? .green : .red)
                      }
                  }
                  .padding()
                  .background(
                      selectedAnswer == option ?
                          (isCorrect == true ? Color.green.opacity(0.3) : Color.red.opacity(0.3)) :
                          Color.gray.opacity(0.1)
                  )
                  .cornerRadius(8)
              }
              .disabled(selectedAnswer != nil)
          }
      }
      .padding()
      .background(Color.white)
      .cornerRadius(12)
      .shadow(radius: 2)
  }
  
  private func checkAnswer(_ option: String) -> Bool {
      return option == question.correctAnswer
  }
}

// 기존 컴포넌트들은 유지
private struct ExplanationView: View {
   let explanation: String
   
   var body: some View {
       VStack(alignment: .leading, spacing: 12) {
           Text(explanation)
               .font(.body)
               .foregroundColor(.secondary)
               .padding()
               .background(Color.blue.opacity(0.1))
               .cornerRadius(10)
               .fixedSize(horizontal: false, vertical: true)
       }
       .transition(.move(edge: .top).combined(with: .opacity))
   }
}

private struct UtilityButtons: View {
   @Binding var showExplanation: Bool
   @Binding var isSaved: Bool
   @ObservedObject var studyViewModel: StudyViewModel
   
   var body: some View {
       Group {
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
           
           Button(action: {
               if let currentQuestion = studyViewModel.currentQuestion {
                   Task {
                       await studyViewModel.toggleSaveQuestion(currentQuestion)
                       withAnimation {
                           isSaved.toggle()
                       }
                   }
               }
           }) {
               Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                   .foregroundColor(.blue)
                   .font(.system(size: 24))
                   .padding(8)
                   .background(Circle().fill(Color.blue.opacity(0.2)))
           }
       }
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
                   isCorrect = nil  // 다음 문제로 넘어갈 때 리셋
                   showExplanation = false
               }
           } else {
               viewModel.submitAnswer()
               if let currentQuestion = viewModel.currentQuestion,
                  let selectedAnswer = viewModel.selectedAnswer {
                   isCorrect = currentQuestion.correctAnswer.lowercased() == selectedAnswer.lowercased()
               }
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
