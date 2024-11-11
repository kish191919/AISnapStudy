import Foundation
import Combine
import CoreData

class StudyViewModel: ObservableObject {
    @Published private(set) var currentQuestion: Question?
    @Published var selectedAnswer: String?
    @Published var matchingPairs: [String: String] = [:]
    @Published var showExplanation = false
    private var questions: [Question] = []
    private var cancellables = Set<AnyCancellable>()
    private(set) var currentIndex = 0
    
    @Published var correctAnswers: Int = 0 // 정답 개수
    var totalQuestions: Int {
        questions.count
    }
    
    private let context: NSManagedObjectContext
    private var currentSession: CDStudySession?
    
    init(homeViewModel: HomeViewModel, context: NSManagedObjectContext) {
        self.context = context
        
        homeViewModel.$selectedProblemSet
            .compactMap { $0?.questions }
            .sink { [weak self] questions in
                Task { @MainActor in
                    self?.loadQuestions(questions)
                }
            }
            .store(in: &cancellables)
        
        setupCurrentSession()
    }
    
    @MainActor
    func loadQuestions(_ questions: [Question]) {
        print("📝 StudyViewModel - Loading \(questions.count) questions")
        self.questions = questions
        self.currentQuestion = questions.first
        print("✅ First question loaded: \(self.currentQuestion?.question ?? "none")")
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
        case .multipleChoice, .fillInBlanks:
            return selectedAnswer != nil
        case .matching:
            return matchingPairs.count == question.matchingOptions.count
        }
    }
    
    private func resetAnswers() {
        selectedAnswer = nil
        matchingPairs.removeAll()
        showExplanation = false
    }
}
