// ./AISnapStudy/ViewModels/HomeViewModel.swift

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published private(set) var problemSets: [ProblemSet] = []
    @Published private(set) var savedQuestions: [Question] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var correctAnswers: Int = 0
    @Published var totalQuestions: Int = 0
    
    // 여기서 변경된 문제 세트를 StudyViewModel에 알리기 위해 Observable로 변경
    @Published var selectedProblemSet: ProblemSet? {
        didSet {
            guard selectedProblemSet?.id != oldValue?.id else { return }
            
            print("""
            🔄 HomeViewModel - selectedProblemSet changed:
            • Old ID: \(oldValue?.id ?? "none")
            • New ID: \(selectedProblemSet?.id ?? "none")
            • Questions Count: \(selectedProblemSet?.questions.count ?? 0)
            """)
            objectWillChange.send()
        }
    }
    
    private let coreDataService = CoreDataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedData = false
    
    init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Data Loading
    @MainActor
    private func loadInitialData() async {
        guard !hasLoadedData else { return }
        await loadData()
        hasLoadedData = true
    }
    
    @MainActor
    func loadData() async {
        guard !isLoading else { return }
        
        print("🔵 HomeViewModel - Loading data")
        isLoading = true
        error = nil
        
        do {
            let loadedProblemSets = try coreDataService.fetchProblemSets()
            self.problemSets = loadedProblemSets
            
            // Get saved questions from all problem sets
            self.savedQuestions = loadedProblemSets
                .flatMap { $0.questions }
                .filter { $0.isSaved }
            
            // 최근 ProblemSet을 selectedProblemSet으로 설정
            if selectedProblemSet == nil && !problemSets.isEmpty {
                setSelectedProblemSet(problemSets[0])
            }
            
            print("✅ Loaded problem sets: \(problemSets.count)")
            print("✅ Loaded saved questions: \(savedQuestions.count)")
            
        } catch {
            self.error = error
            print("❌ Error in loadData: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Problem Set Management
    @MainActor
    func saveProblemSet(_ problemSet: ProblemSet) async {
        do {
            print("💾 Saving ProblemSet with \(problemSet.questions.count) questions")
            try await coreDataService.saveProblemSet(problemSet)
            
            // 데이터 리로드 대신 문제 세트 직접 추가
            problemSets.insert(problemSet, at: 0)
            setSelectedProblemSet(problemSet)
            
            print("✅ Saved ProblemSet: \(problemSet.questions.count) questions")
        } catch {
            self.error = error
            print("❌ Failed to save ProblemSet: \(error)")
        }
    }
    
    @MainActor
    func setSelectedProblemSet(_ problemSet: ProblemSet?) {
        guard selectedProblemSet?.id != problemSet?.id else { return }
        
        print("🔵 HomeViewModel - Setting selected problem set")
        self.selectedProblemSet = problemSet
        
        if let problemSet = problemSet {
            print("""
            ✅ ProblemSet set successfully:
            • ID: \(problemSet.id)
            • Questions: \(problemSet.questions.count)
            """)
        }
    }
    
    @MainActor
    func clearSelectedProblemSet() {
        setSelectedProblemSet(nil)
    }
    
    // MARK: - Question Management
    @MainActor
    func saveQuestion(_ question: Question) async {
        do {
            try await coreDataService.saveQuestion(question)
            savedQuestions.append(question)
        } catch {
            self.error = error
            print("❌ Error saving question: \(error)")
        }
    }
    
    @MainActor
    func deleteQuestion(_ question: Question) async {
        guard let index = savedQuestions.firstIndex(where: { $0.id == question.id }) else {
            return
        }
        
        let deletedQuestion = savedQuestions.remove(at: index)
        
        do {
            try await coreDataService.deleteQuestion(question)
        } catch {
            self.error = error
            savedQuestions.insert(deletedQuestion, at: index)
            print("❌ Error deleting question: \(error)")
        }
    }
    
    // MARK: - Debug Helper
    @MainActor
    func verifyProblemSetStorage() {
        Task {
            do {
                let storedSets = try coreDataService.fetchProblemSets()
                print("""
                📝 Stored ProblemSets:
                • Count: \(storedSets.count)
                • Details: \(storedSets.map { "[\($0.id): \($0.questions.count) questions]" })
                """)
            } catch {
                print("❌ Failed to verify storage: \(error)")
            }
        }
    }
}
