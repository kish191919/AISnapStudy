
// ViewModels/HomeViewModel.swift

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published private(set) var problemSets: [ProblemSet] = []
    @Published private(set) var savedQuestions: [Question] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var selectedProblemSet: ProblemSet?
    
    private let coreDataService = CoreDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await loadData()
        }
    }
    
    // MARK: - Data Loading
    @MainActor
    func loadData() async {
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
            
            if selectedProblemSet == nil, let mostRecent = problemSets.first {
                selectedProblemSet = mostRecent
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
            try await Task.detached {
                try CoreDataService.shared.saveProblemSet(problemSet)
            }.value
            
            await self.loadData()
        } catch {
            self.error = error
            print("❌ Error saving problem set: \(error)")
        }
    }
    
    func setSelectedProblemSet(_ problemSet: ProblemSet?) {
        print("🔵 HomeViewModel - Setting selected problem set")
        if let problemSet = problemSet {
            print("New selected problem set ID: \(problemSet.id)")
            print("Questions count: \(problemSet.questionCount)")
        } else {
            print("Clearing selected problem set")
        }
        self.selectedProblemSet = problemSet
    }
    
    func clearSelectedProblemSet() {
        self.selectedProblemSet = nil
    }
    
    func selectProblemSet(_ problemSet: ProblemSet?) {
        self.selectedProblemSet = problemSet
    }
    
    // MARK: - Question Management
    @MainActor
    func saveQuestion(_ question: Question) async {
        do {
            try await Task.detached {
                let questions = (try? CoreDataService.shared.fetchProblemSets())?.flatMap { $0.questions } ?? []
                var updatedQuestions = questions
                updatedQuestions.append(question)
                // 여기서 CoreData를 통해 question 저장 로직 구현 필요
            }.value
            
            self.savedQuestions.append(question)
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
            try await Task.detached {
                // 여기서 CoreData를 통해 question 삭제 로직 구현 필요
            }.value
        } catch {
            self.error = error
            self.savedQuestions.insert(deletedQuestion, at: index)
            print("❌ Error deleting question: \(error)")
        }
    }
}
