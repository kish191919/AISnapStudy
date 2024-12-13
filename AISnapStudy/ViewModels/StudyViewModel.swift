import Foundation
import Combine
import CoreData

@MainActor
class StudyViewModel: ObservableObject {
    // OpenAIService 타입 참조 추가
    typealias QuestionInput = OpenAIService.QuestionInput
    typealias QuestionParameters = OpenAIService.QuestionParameters
    private weak var statViewModel: StatViewModel?

    @Published private(set) var loadedQuestions: [Question] = []
    @Published private(set) var loadingProgress = 0

    private let openAIService: OpenAIService

    @Published private(set) var currentQuestion: Question?
    @Published var selectedAnswer: String?
    @Published var showExplanation = false
    private var questions: [Question] = []
    private var cancellables = Set<AnyCancellable>()
    @Published private(set) var currentIndex = 0
    @Published var correctAnswers: Int = 0

    // 질문 생성 관련 프로퍼티 추가
    @Published var isGeneratingQuestions = false
    @Published var generatedQuestionCount = 0
    @Published var totalExpectedQuestions = 0
    @Published var generatedQuestions: [Question] = []
    @Published var isLoadingQuestions: Bool = false
    
    func setStatViewModel(_ viewModel: StatViewModel) {
        self.statViewModel = viewModel
        print("StatViewModel connected: \(viewModel)")  // 연결 확인 로그
    }

    func updateGeneratedQuestions(_ question: Question) {
        generatedQuestions.append(question)
        generatedQuestionCount = generatedQuestions.count
    }

    func setTotalExpectedQuestions(_ total: Int) {
        totalExpectedQuestions = total
    }

    var totalQuestions: Int {
        questions.count
    }

    private let context: NSManagedObjectContext
    private var currentSession: CDStudySession?
    private let homeViewModel: HomeViewModel

    private var hasInitialized = false

    init(homeViewModel: HomeViewModel, context: NSManagedObjectContext) {
        self.context = context
        self.homeViewModel = homeViewModel
        
        // OpenAIService 싱글톤 인스턴스 사용
        self.openAIService = OpenAIService.shared

        Task { @MainActor in
            homeViewModel.$selectedProblemSet
                .compactMap { $0 }
                .removeDuplicates(by: { $0.id == $1.id })
                .receive(on: RunLoop.main)
                .sink { [weak self] problemSet in
                    guard let self = self else { return }
                    Task {
                        await self.resetState()
                        await MainActor.run {
                            self.loadQuestions(problemSet.questions)
                        }
                    }
                }
                .store(in: &self.cancellables)
        }

        setupCurrentSession()
    }


    func startQuestionGeneration(input: QuestionInput, parameters: QuestionParameters) async {
        isLoadingQuestions = true
        loadingProgress = 0
        loadedQuestions = []
        isGeneratingQuestions = true
        generatedQuestionCount = 0
        generatedQuestions = []

        // 예상되는 총 질문 수 계산
        let totalQuestions = parameters.questionTypes.values.reduce(0, +)
        setTotalExpectedQuestions(totalQuestions)

        do {
            let questions = try await openAIService.generateQuestions(from: input, parameters: parameters)
            await MainActor.run {
                questions.forEach { question in
                    updateGeneratedQuestions(question)
                }
            }
        } catch {
            print("Error generating questions: \(error)")
        }

        await MainActor.run {
            isGeneratingQuestions = false
            loadedQuestions = generatedQuestions
            loadingProgress = 100
            isLoadingQuestions = false
        }
    }
    
    @MainActor
    func loadUpdatedQuestions(_ problemSetId: String) async {
        if let updatedSet = try? await homeViewModel.fetchUpdatedProblemSet(problemSetId) {
            questions = updatedSet.questions
            currentQuestion = questions.first
            print("📝 Loaded updated questions from CoreData - count: \(updatedSet.questions.count)")
        }
    }
    
   
    @MainActor
    func resetState() async {
        print("🔄 Performing complete state reset")
        currentIndex = 0
        selectedAnswer = nil
        showExplanation = false
        correctAnswers = 0
        
        questions.removeAll()
        
        if let problemSet = homeViewModel.selectedProblemSet {
            // CoreData에서 최신 상태 가져오기 시도
            if let updatedSet = try? await homeViewModel.fetchUpdatedProblemSet(problemSet.id) {
                questions = updatedSet.questions
                currentQuestion = updatedSet.questions.first
                print("📝 Updated questions loaded from CoreData - count: \(updatedSet.questions.count)")
            } else {
                // 실패 시 메모리의 문제 세트 사용
                questions = problemSet.questions
                currentQuestion = problemSet.questions.first
                print("⚠️ Using memory cached questions - count: \(problemSet.questions.count)")
            }
        }
        
        print("""
        ✅ State reset complete:
        • Questions count: \(questions.count)
        • Current index: \(currentIndex)
        • Current question: \(currentQuestion?.question ?? "No question loaded")
        """)
    }
   
    @MainActor
    func loadQuestions(_ newQuestions: [Question]) {
        guard questions != newQuestions else {
            print("⚠️ Same questions already loaded, skipping")
            return
        }
        
        print("📝 Loading fresh set of \(newQuestions.count) questions")
        questions = newQuestions
        currentIndex = 0
        currentQuestion = questions.isEmpty ? nil : questions[0]
        
        print("✅ Questions loaded: \(currentQuestion?.question ?? "No question loaded")")
    }
   
    private func setupCurrentSession() {
        let session = CDStudySession(context: context)
        session.startTime = Date()
        session.questions = NSSet() // Initialize empty questions set
        currentSession = session
        saveContext()
        print("📝 New study session created at: \(session.startTime?.description ?? "unknown")")
    }
   
    func submitAnswer() {
        guard let currentQuestion = currentQuestion else { return }
        
        let trimmedSelected = selectedAnswer?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedCorrect = currentQuestion.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isCorrect = trimmedSelected == trimmedCorrect
        
        if isCorrect {
            correctAnswers += 1
        }
        
        // StatViewModel 업데이트 및 CoreData 저장
        NotificationCenter.default.post(
            name: .studyProgressDidUpdate,
            object: nil,
            userInfo: [
                "currentIndex": currentIndex + 1,
                "correctAnswers": correctAnswers
            ]
        )
        
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
            if context.hasChanges {
                try context.save()
                print("✅ Context saved successfully")
            }
        } catch {
            print("❌ Failed to save context: \(error)")
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
       case .multipleChoice, .trueFalse:
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
