// ./AISnapStudy/ViewModels/StudyViewModel.swift

import Foundation
import Combine

class StudyViewModel: ObservableObject {
    @Published private(set) var currentQuestion: Question?
    @Published var selectedAnswer: String?
    @Published var matchingPairs: [String: String] = [:]
    @Published var showExplanation = false
    private var questions: [Question] = []
    private var cancellables = Set<AnyCancellable>()
    private(set) var currentIndex = 0
    
    init(homeViewModel: HomeViewModel) {
        homeViewModel.$selectedProblemSet
            .compactMap { $0?.questions }
            .sink { [weak self] questions in
                Task { @MainActor in
                    self?.loadQuestions(questions)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func loadQuestions(_ questions: [Question]) {
        print("📝 StudyViewModel - Loading \(questions.count) questions")
        self.questions = questions
        self.currentQuestion = questions.first
        print("✅ First question loaded: \(self.currentQuestion?.question ?? "none")")
    }
    
    var hasQuestions: Bool {
        return !questions.isEmpty
    }
    
    var totalQuestions: Int {
        questions.count
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
    
    private func updateCurrentQuestion() {
        guard currentIndex < questions.count else { return }
        currentQuestion = questions[currentIndex]
        selectedAnswer = nil
        matchingPairs.removeAll()
        showExplanation = false
    }
    
    func nextQuestion() {
        guard currentIndex < questions.count - 1 else { return }
        currentIndex += 1
        updateCurrentQuestion()
    }
    
    func submitAnswer() {
        showExplanation = true
    }
    
    func saveProgress() {
        print("Saving progress...")
    }
    
    private func resetAnswers() {
        selectedAnswer = nil
        matchingPairs.removeAll()
        showExplanation = false
    }
}
