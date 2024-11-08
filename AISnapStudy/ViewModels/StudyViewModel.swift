
// ViewModels/StudyViewModel.swift
import Foundation

class StudyViewModel: ObservableObject {
    @Published var currentQuestion: Question?
    @Published var selectedAnswer: String?
    @Published var matchingPairs: [String: String] = [:]
    @Published var showExplanation = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private var questions: [Question] = []
    private var currentIndex = 0
    private var answers: [String: String] = [:] // [QuestionId: UserAnswer]
    private var score: Int?
    
    // MARK: - Computed Properties
    var currentQuestionIndex: Int {
        currentIndex
    }
    
    var totalQuestions: Int {
        questions.count
    }
    
    var canSubmit: Bool {
        guard let question = currentQuestion else { return false }
        
        switch question.type {
        case .multipleChoice, .fillInBlanks:
            return selectedAnswer != nil
        case .matching:
            return matchingPairs.count == question.matchingOptions.count
        }
    }
    
    var progress: String {
        "\(currentIndex + 1)/\(questions.count)"
    }
    
    var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }
    
    var questionProgress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(questions.count)
    }
    
    // MARK: - Public Methods
    func loadQuestions(_ questions: [Question]) {
        print("🔵 StudyViewModel - Loading questions")
        print("Number of questions received: \(questions.count)")
        
        self.questions = questions
        currentIndex = 0
        answers.removeAll()
        score = nil
        
        print("Reset current index to 0")
        print("Cleared previous answers and score")
        
        updateCurrentQuestion()
    }
    
    func submitAnswer() {
        guard let question = currentQuestion else { return }
        
        // Store the answer based on question type
        switch question.type {
        case .multipleChoice, .fillInBlanks:
            if let answer = selectedAnswer {
                answers[question.id] = answer
                checkAnswer(answer, for: question)
            }
        case .matching:
            checkMatchingAnswers(for: question)
            answers[question.id] = formatMatchingAnswers()
        }
        
        showExplanation = true
    }
    
    func nextQuestion() {
        currentIndex += 1
        updateCurrentQuestion()
    }
    
    // updateCurrentQuestion 메소드 수정
    private func updateCurrentQuestion() {
        print("🔵 StudyViewModel - Updating current question")
        print("Current index: \(currentIndex)")
        print("Total questions: \(questions.count)")
        
        guard currentIndex < questions.count else {
            print("❌ Current index exceeds questions count")
            currentQuestion = nil
            calculateFinalScore()
            return
        }
        
        currentQuestion = questions[currentIndex]
        if let question = currentQuestion {
            print("✅ Set current question:")
            print("ID: \(question.id)")
            print("Type: \(question.type)")
            print("Question: \(question.question)")
        }
        
        resetAnswers()
    }
    
    private func resetAnswers() {
        selectedAnswer = nil
        matchingPairs.removeAll()
        showExplanation = false
    }
    
    private func checkAnswer(_ answer: String, for question: Question) {
        // 답변 체크 로직 구현
        // 여기서는 단순히 정답과 비교만 하지만,
        // 실제로는 더 복잡한 로직이 들어갈 수 있습니다.
        if answer == question.correctAnswer {
            // 정답 처리
        }
    }
    
    private func checkMatchingAnswers(for question: Question) {
        // 매칭 문제 답변 체크 로직 구현
        // matchingPairs의 각 쌍이 올바른지 확인
    }
    
    private func formatMatchingAnswers() -> String {
        // 매칭 답변을 저장 가능한 형태로 변환
        // 예: "A:1,B:2,C:3"
        return matchingPairs.map { "\($0.key):\($0.value)" }.joined(separator: ",")
    }
    
    private func calculateFinalScore() {
        // 최종 점수 계산 로직
        var correctCount = 0
        for (questionId, userAnswer) in answers {
            if let question = questions.first(where: { $0.id == questionId }),
               userAnswer == question.correctAnswer {
                correctCount += 1
            }
        }
        
        score = Int((Double(correctCount) / Double(questions.count)) * 100)
    }
    
    // MARK: - Session Management
    func saveProgress() {
        guard !questions.isEmpty else { return }
        
        // StudySession 생성 및 저장 로직
        let session = StudySession(
            problemSet: ProblemSet(
                id: UUID().uuidString,
                title: "Study Session",
                subject: questions.first?.subject ?? .math,
                difficulty: questions.first?.difficulty ?? .medium,
                questions: questions,
                createdAt: Date()
            ),
            startTime: Date(),
            endTime: Date(),
            answers: answers,
            score: score
        )
        
        // StorageService를 통해 세션 저장
        do {
            try StorageService().saveStudySession(session)
        } catch {
            self.error = error
        }
    }
}
