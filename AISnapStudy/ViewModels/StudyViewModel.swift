import Foundation
import Combine
import CoreData

@MainActor
class StudyViewModel: ObservableObject {
    @Published private(set) var currentQuestion: Question?
    @Published var selectedAnswer: String?
    @Published var showExplanation = false
    private var questions: [Question] = []
    private var cancellables = Set<AnyCancellable>()
    @Published private(set) var currentIndex = 0  // @Published 추가
    
    @Published var correctAnswers: Int = 0
    var totalQuestions: Int {
        questions.count
    }
    
    private let context: NSManagedObjectContext
    private var currentSession: CDStudySession?
    private let homeViewModel: HomeViewModel // Add this line to declare homeViewModel
    
    private var hasInitialized = false
    
    init(homeViewModel: HomeViewModel, context: NSManagedObjectContext) {

        self.context = context
        self.homeViewModel = homeViewModel // Initialize homeViewModel
        
        Task { @MainActor in  // Task 추가
            homeViewModel.$selectedProblemSet
                .compactMap { $0 }
                .removeDuplicates(by: { $0.id == $1.id })
                .receive(on: RunLoop.main)
                .sink { [weak self] problemSet in
                    guard let self = self else { return }
                    self.resetState()
                    Task { @MainActor in
                        self.loadQuestions(problemSet.questions)
                    }
                }
                .store(in: &self.cancellables)
        }
        
        setupCurrentSession()
    }
        
    func resetState() {
        print("🔄 Performing complete state reset")
        currentIndex = 0
        selectedAnswer = nil
        showExplanation = false
        correctAnswers = 0
        
        // 중복 호출 방지를 위해 clear 후 로드
        questions.removeAll()
        
        // 질문 로드 초기화 및 첫 번째 질문 설정
        if let problemSet = homeViewModel.selectedProblemSet {
            loadQuestions(problemSet.questions)
        }

        currentQuestion = questions.first
        print("✅ Reset to first question with question: \(currentQuestion?.question ?? "No question loaded"), currentIndex: \(currentIndex)")
    }

    
    func loadQuestions(_ newQuestions: [Question]) {
        print("📝 Loading fresh set of \(newQuestions.count) questions")
        questions = newQuestions
        currentIndex = 0 // 명시적으로 currentIndex를 0으로 설정
        currentQuestion = questions.isEmpty ? nil : questions[0]
        
        print("✅ First question loaded explicitly: \(currentQuestion?.question ?? "No question loaded") with currentIndex: \(currentIndex)")
    }
    
    private func setupCurrentSession() {
        let session = CDStudySession(context: context)
        session.startTime = Date()
        currentSession = session
        saveContext()
    }
    
    func submitAnswer() {
        guard let currentQuestion = currentQuestion else { return }
        
        // Check if the answer is correct and update count
        let isCorrect = currentQuestion.correctAnswer == selectedAnswer
        if isCorrect {
            correctAnswers += 1
        }
        
        // Save isCorrect status in current session
        if let session = currentSession {
            let question = CDQuestion(context: context)
            question.isCorrect = isCorrect
            question.question = currentQuestion.question
            question.session = session
            saveContext()
        }
        
        showExplanation = true
    }
    
    func nextQuestion() {
        guard currentIndex < questions.count - 1 else { return }
        currentIndex += 1
        currentQuestion = questions[currentIndex]
        resetAnswers()
    }
    
    func saveProgress() {
        print("Saving progress...")
        saveContext()
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    var hasQuestions: Bool {
        return !questions.isEmpty
    }
    
    var progress: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(totalQuestions)
    }
    
    var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }
    
    var canSubmit: Bool {
        guard let question = currentQuestion else { return false }
        
        switch question.type {
        case .multipleChoice, .fillInBlanks, .trueFalse:  // trueFalse 케이스 추가
            return selectedAnswer != nil
        }
    }
    
    private func resetAnswers() {
        selectedAnswer = nil
        showExplanation = false
    }
}

extension StudyViewModel {
    @MainActor
    func toggleSaveQuestion(_ question: Question) async {
        var updatedQuestion = question
        updatedQuestion.isSaved.toggle()
        
        do {
            if updatedQuestion.isSaved {
                try await homeViewModel.saveQuestion(updatedQuestion)
            } else {
                try await homeViewModel.deleteQuestion(updatedQuestion)
            }
            print("✅ Question save state toggled successfully")
        } catch {
            print("❌ Failed to toggle question save state: \(error)")
        }
    }
}
