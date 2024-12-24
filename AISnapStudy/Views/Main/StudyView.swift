import SwiftUI
import CoreData

struct StudyView: View {
   @Environment(\.managedObjectContext) private var context
   @Binding var selectedTab: Int
   @ObservedObject var studyViewModel: StudyViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel  // 추가
   let questions: [Question]
   
   @State private var showExplanation: Bool = false
    @State private var isCorrect: Bool? = nil  // 이 부분이 중요합니다
   @State private var isSaved: Bool = false
   @State private var previewSelectedAnswer: String? = nil  // 추가
   @State private var previewIsCorrect: Bool? = nil        // 추가
    @State private var showDeleteAlert = false  // 추가
    @State private var questionToDelete: Question? = nil  // 추가
    @State private var showCelebration = false
   
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
                    GeneratingQuestionsOverlay(
                        questionCount: studyViewModel.totalExpectedQuestions
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .transition(.opacity)
                    
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
            } else if !studyViewModel.hasQuestions {
                Text("No questions available")
                    .font(.title3)
                    .foregroundColor(.gray)
            } else {
                VStack {
                    Spacer()
                        .frame(height: 20)
                    // 진행 상태와 스트릭을 함께 표시하는 부분 추가
                    HStack {
                        Text("\(studyViewModel.currentIndex + 1) / \(studyViewModel.totalQuestions)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // 스트릭 표시 추가
                        StreakIndicator(streak: studyViewModel.currentStreak)
                            .animation(.spring(), value: studyViewModel.currentStreak)
                    }
                    .padding(.horizontal)
                    
                    
                    ProgressView(value: Double(min(studyViewModel.currentIndex + 1, studyViewModel.totalQuestions)),
                               total: Double(studyViewModel.totalQuestions))
                        .progressViewStyle(CustomProgressViewStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    
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
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                        
                                    case .trueFalse:
                                        TrueFalseView(
                                            question: currentQuestion,
                                            selectedAnswer: $studyViewModel.selectedAnswer,
                                            showExplanation: studyViewModel.showExplanation,
                                            isCorrect: isCorrect  // 여기 isCorrect 바인딩이 문제일 수 있습니다
                                        )
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                    }
                                    
                                    if showExplanation && studyViewModel.showExplanation {
                                        ExplanationView(explanation: currentQuestion.explanation)
                                    }
                                }
                            }
                            .padding()
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: studyViewModel.currentIndex)
                        }
                        
                        VStack {
                            Divider()
                            
                            HStack(spacing: 12) {
                                if studyViewModel.showExplanation {
                                    UtilityButtons(
                                        showExplanation: $showExplanation,
                                        isSaved: $isSaved,
                                        studyViewModel: studyViewModel,
                                        onDelete: {
                                            questionToDelete = studyViewModel.currentQuestion
                                            showDeleteAlert = true
                                        }
                                    )
                                }
                                
                                ActionButton(
                                    viewModel: studyViewModel,
                                    selectedTab: $selectedTab,
                                    isCorrect: $isCorrect,
                                    showExplanation: $showExplanation,
                                    showCelebration: $showCelebration  // 추가
                                )
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                        }
                    }
                }
            }
        }
        .alert("Delete Question", isPresented: $showDeleteAlert) {  // 추가
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let question = questionToDelete,
                           let problemSet = homeViewModel.selectedProblemSet {
                            Task {
                                await homeViewModel.removeQuestionFromProblemSet(
                                    question.id,
                                    from: problemSet
                                )
                            }
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this question?")
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
                    .animation(.spring(response: 0.45), value: configuration.fractionCompleted)
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
   let onDelete: () -> Void
   
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
           
           Button(action: onDelete) {
               Image(systemName: "trash")
                   .foregroundColor(.red)
                   .font(.system(size: 24))
                   .padding(8)
                   .background(Circle().fill(Color.red.opacity(0.2)))
           }
       }
   }
}

private struct ActionButton: View {
   @ObservedObject var viewModel: StudyViewModel
   @Binding var selectedTab: Int
   @Binding var isCorrect: Bool?
   @Binding var showExplanation: Bool
    @Binding var showCelebration: Bool  // 추가
   
   var body: some View {
       Button(action: {
           if viewModel.showExplanation {
               if viewModel.isLastQuestion {
                   viewModel.saveProgress()
                   selectedTab = 3
               } else {
                   withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                       viewModel.nextQuestion()  // viewModel을 통해 호출
                       isCorrect = nil
                       showExplanation = false
                       showCelebration = false  // 리셋
                   }

               }
           } else {
               viewModel.submitAnswer()
               if let currentQuestion = viewModel.currentQuestion,
                  let selectedAnswer = viewModel.selectedAnswer {
                   let correct = currentQuestion.correctAnswer.lowercased() == selectedAnswer.lowercased()
                   isCorrect = correct
                   if correct {
                       showCelebration = true  // 정답일 때 축하 애니메이션 표시
                   }
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

struct GeneratingQuestionsOverlay: View {
    let questionCount: Int  // 필요하지만 사용하지 않을 매개변수
    @State private var rotation: Double = 0
    @State private var dotScale: CGFloat = 1.0
    @State private var currentTipIndex = 0
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // 배경색을 흰색으로 변경
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Main Animation Circle
                ZStack {
                    // Outer rotating circle
                    Circle()
                        .stroke(lineWidth: 6)
                        .frame(width: 200, height: 200)
                        .foregroundColor(.blue.opacity(0.3))
                        .rotationEffect(.degrees(rotation))
                    
                    // Inner gradient circle
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 10
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-rotation))
                    
                    // Center content - 텍스트 색상을 검은색으로 변경하고 Questions 수 표시 제거
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("Generating")
                            .font(.title)
                            .foregroundColor(.black)  // 검은색으로 변경
                        Text("Questions")
                            .font(.title2)
                            .foregroundColor(.black)  // 검은색으로 변경
                    }
                }
                .onAppear {
                    withAnimation(
                        .linear(duration: 4)
                        .repeatForever(autoreverses: false)
                    ) {
                        rotation = 360
                    }
                }
                
                // Animated Dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                            .scaleEffect(dotScale)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: dotScale
                            )
                    }
                }
                .onAppear {
                    dotScale = 0.5
                }
                
                // Tips Section
                VStack(spacing: 12) {
                    Text(tips[currentTipIndex])
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .frame(height: 60)
                        .transition(.opacity.combined(with: .slide))
                        .id(currentTipIndex)
                        .animation(.easeInOut, value: currentTipIndex)
                    
                    // Progress Dots
                    HStack(spacing: 6) {
                        ForEach(0..<tips.count) { index in
                            Circle()
                                .fill(index == currentTipIndex ? Color.white : Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.blue.opacity(0.8))
                )
            }
            .padding(30)
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentTipIndex = (currentTipIndex + 1) % tips.count
            }
        }
    }
    
    private let tips = [
        "Creating personalized questions just for you...",
        "Analyzing content to ensure the best learning experience...",
        "Getting ready to challenge your knowledge...",
        "Preparing explanations to help you understand better...",
        "Almost there! Your questions are being finalized..."
    ]
}

struct GeneratedQuestionPreviewCard: View {
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: question.type == .multipleChoice ? "list.bullet.circle.fill" : "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text(question.type == .multipleChoice ? "Multiple Choice" : "True/False")
                    .font(.caption)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            Text(question.question)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 스트릭 인디케이터 컴포넌트 추가
struct StreakIndicator: View {
    let streak: Int
    @State private var isAnimating = false
    
    private var streakInfo: (color: Color, icon: String, description: String) {
        switch streak {
        case 0:
            return (.gray, "star", "Start your streak!")
        case 1...2:
            return (.orange, "flame", "Good Start!")
        case 3...4:
            return (.orange, "flame.fill", "Keep Going!")
        case 5...6:
            return (.red, "flame.circle.fill", "On Fire! 🔥")
        case 7...9:
            return (.purple, "sparkles", "Unstoppable!")
        case 10...14:
            return (.blue, "star.circle.fill", "Perfect! ⭐️")
        case 15...19:
            return (.green, "crown.fill", "Champion! 👑")
        case 20...24:
            return (.yellow, "medal.fill", "Genius! 🏅")
        default:
            return (.pink, "trophy.fill", "Legendary! 🏆")
        }
    }
    
    private var animation: Animation {
        Animation.spring(response: 0.5, dampingFraction: 0.6)
            .repeatCount(1)
    }
    
    var body: some View {
        if streak > 0 {
            HStack(spacing: 8) {
                // 아이콘과 파티클 효과
                ZStack {
                    // 파티클 효과
                    ForEach(0..<3) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: 8))
                            .foregroundColor(streakInfo.color)
                            .offset(x: isAnimating ? CGFloat.random(in: -20...20) : 0,
                                    y: isAnimating ? CGFloat.random(in: -20...20) : 0)
                            .opacity(isAnimating ? 0 : 1)
                            .animation(
                                animation.delay(Double(i) * 0.1),
                                value: isAnimating
                            )
                    }
                    
                    // 메인 아이콘
                    Image(systemName: streakInfo.icon)
                        .font(.system(size: 24))
                        .foregroundColor(streakInfo.color)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(animation, value: isAnimating)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak) Streak")
                        .font(.headline)
                        .foregroundColor(streakInfo.color)
                    
                    Text(streakInfo.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(streakInfo.color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(streakInfo.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .onAppear {
                withAnimation {
                    isAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isAnimating = false
                }
            }
            .onChange(of: streak) { _ in
                withAnimation {
                    isAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isAnimating = false
                }
            }
        }
    }
}

