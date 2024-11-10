
// ViewModels/StudyViewModel.swift
import Foundation

class StudyViewModel: ObservableObject {
    @Published private(set) var currentQuestion: Question?
    @Published var selectedAnswer: String?
    @Published var matchingPairs: [String: String] = [:]
    @Published var showExplanation = false
    @Published private(set) var currentIndex = 0
    
    private var questions: [Question] = []
    
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
    
    @MainActor
    func loadQuestions(_ questions: [Question]) {
        print("📥 StudyViewModel - Loading \(questions.count) questions")
        self.questions = questions
        self.currentIndex = 0
        self.selectedAnswer = nil
        self.showExplanation = false
        updateCurrentQuestion()
    }
    
    private func updateCurrentQuestion() {
            guard currentIndex < questions.count else { return }
            currentQuestion = questions[currentIndex]
            // 새로운 문제로 넘어갈 때 상태 초기화
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
        // 진행 상황 저장 로직 구현
        print("Saving progress...")
    }
    
    private func resetAnswers() {
        selectedAnswer = nil
        matchingPairs.removeAll()
        showExplanation = false
    }
}
