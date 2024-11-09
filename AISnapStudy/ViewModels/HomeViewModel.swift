
// ViewModels/HomeViewModel.swift

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published private(set) var problemSets: [ProblemSet] = []
    @Published private(set) var savedQuestions: [Question] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var selectedProblemSet: ProblemSet? {
            didSet {
                print("""
                🔄 HomeViewModel - selectedProblemSet changed:
                • Old ID: \(oldValue?.id ?? "none")
                • New ID: \(selectedProblemSet?.id ?? "none")
                • Questions Count: \(selectedProblemSet?.questions.count ?? 0)
                """)
                objectWillChange.send()  // 명시적으로 변경 알림
            }
        }
    
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
            
            // 가장 최근 ProblemSet을 selectedProblemSet으로 설정
            if selectedProblemSet == nil && !problemSets.isEmpty {
                selectedProblemSet = problemSets[0] // 첫 번째 ProblemSet 선택
                print("✅ Selected ProblemSet set to: \(problemSets[0].id)")
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
            await loadData() // 저장 후 데이터 리로드
            
            if let saved = try? await coreDataService.fetchProblemSets().first {
                print("✅ Verified saved ProblemSet: \(saved.questions.count) questions")
            }
        } catch {
            self.error = error
            print("❌ Failed to save ProblemSet: \(error)")
        }
    }
    
    @MainActor
    func setSelectedProblemSet(_ problemSet: ProblemSet?) {
        print("🔵 HomeViewModel - Setting selected problem set")
        self.selectedProblemSet = problemSet
        objectWillChange.send()  // 명시적으로 변경 알림
        
        if let problemSet = problemSet {
            print("""
            ✅ ProblemSet set successfully:
            • ID: \(problemSet.id)
            • Questions: \(problemSet.questions.count)
            """)
        }
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

extension HomeViewModel {
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
