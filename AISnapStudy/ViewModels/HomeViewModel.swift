// ./AISnapStudy/ViewModels/HomeViewModel.swift

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var studyViewModel: StudyViewModel?
    @Published private(set) var problemSets: [ProblemSet] = []
    @Published private(set) var savedQuestions: [Question] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var selectedProblemSet: ProblemSet?
//    @Published var correctAnswers: Int = 0
    @Published var totalQuestions: Int = 0

    
    private let coreDataService = CoreDataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedData = false
    
    // Singleton instance
    static let shared = HomeViewModel()

    
    init() {
        Task {
            await loadInitialData()
        }
    }
    // 현재 세션의 점수 관련 속성 추가
    var currentSessionScore: Int {
        return studyViewModel?.correctAnswers ?? 0
    }
    
    var currentSessionTotalQuestions: Int {
        return selectedProblemSet?.questions.count ?? 0
    }
    
    func setStudyViewModel(_ viewModel: StudyViewModel) {
        print("📱 Setting StudyViewModel in HomeViewModel")
        self.studyViewModel = viewModel
    }
    
    @MainActor
    func resetAndSetProblemSet(_ problemSet: ProblemSet) async {
        print("🔄 Starting complete ProblemSet reset")
        
        // 새로운 ProblemSet 설정
        self.selectedProblemSet = problemSet
        
        // StudyViewModel이 nil이 아닌지 확인
        guard let studyVM = studyViewModel else {
            print("❌ StudyViewModel is nil")
            return
        }
        
        // 상태 리셋 및 문제 다시 로드
        await studyVM.resetState()
        studyVM.loadQuestions(problemSet.questions)
        
        print("""
        ✅ ProblemSet reset complete:
        • ID: \(problemSet.id)
        • Questions: \(problemSet.questions.count)
        • Index reset to 0
        • Current Question: \(studyVM.currentQuestion?.question ?? "none")
        """)
    }
    
    func updateProblemSetSubject(_ problemSet: ProblemSet, to newSubject: SubjectType) async {
        do {
            // 1. 새로운 ProblemSet 인스턴스 생성
            let updatedSet = ProblemSet(
                id: UUID().uuidString,  // 새로운 ID 생성
                subject: newSubject,
                subjectType: newSubject is DefaultSubject ? "default" : "custom",
                subjectId: newSubject.id,
                subjectName: newSubject.displayName,
                questions: problemSet.questions,
                createdAt: problemSet.createdAt,
                educationLevel: problemSet.educationLevel,
                name: problemSet.name
            )
            
            // 2. 기존 ProblemSet 삭제
            try await coreDataService.deleteProblemSet(problemSet)
            
            // 3. 메모리에서 기존 ProblemSet 제거
            problemSets.removeAll { $0.id == problemSet.id }
            
            // 4. 새로운 ProblemSet 저장
            try await coreDataService.saveProblemSet(updatedSet)
            problemSets.append(updatedSet)
            
            // 5. selectedProblemSet 업데이트
            if selectedProblemSet?.id == problemSet.id {
                selectedProblemSet = updatedSet
            }
            
            // 6. UI 업데이트
            objectWillChange.send()
            
            print("""
            ✅ Problem Set subject updated:
            • Old Subject: \(problemSet.subjectName)
            • New Subject: \(newSubject.displayName)
            • Old ID: \(problemSet.id)
            • New ID: \(updatedSet.id)
            """)
        } catch {
            print("❌ Failed to update problem set subject: \(error)")
        }
    }
    
    @MainActor
    func removeQuestionFromProblemSet(_ questionId: String, from problemSet: ProblemSet) async {
        let updatedProblemSet = problemSet.removeQuestion(questionId)
        
        do {
            try await coreDataService.updateProblemSet(problemSet, newName: problemSet.name) // newName 매개변수 추가
            if let index = problemSets.firstIndex(where: { $0.id == problemSet.id }) {
                problemSets[index] = updatedProblemSet
            }
            
            if selectedProblemSet?.id == problemSet.id {
                selectedProblemSet = updatedProblemSet
            }
        } catch {
            print("❌ Failed to remove question: \(error)")
        }
    }
    
    // MARK: - Data Loading
    @MainActor
    private func loadInitialData() async {
        guard !hasLoadedData else { return }
        
        do {
            print("🔵 HomeViewModel - Initial data loading")
            let loadedProblemSets = try coreDataService.fetchProblemSets()
            self.problemSets = loadedProblemSets
            self.savedQuestions = try coreDataService.fetchSavedQuestions()
            
            if selectedProblemSet == nil && !problemSets.isEmpty {
                setSelectedProblemSet(problemSets[0])
            }
            
            hasLoadedData = true
            print("✅ Initial data loaded successfully")
        } catch {
            print("❌ Failed to load initial data: \(error)")
        }
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
    // 파일: ./AISnapStudy/ViewModels/HomeViewModel.swift

    @MainActor
    func saveProblemSet(_ problemSet: ProblemSet) async {
        do {
            // 1. 기존 ProblemSet 찾기
            if let existingSet = problemSets.first(where: {
                $0.questions == problemSet.questions && $0.id != problemSet.id
            }) {
                // 2. 기존 ProblemSet 삭제
                try await coreDataService.deleteProblemSet(existingSet)
                problemSets.removeAll { $0.id == existingSet.id }
            }

            // 3. 새로운 ProblemSet 저장
            try await coreDataService.saveProblemSet(problemSet)
            problemSets.insert(problemSet, at: 0)
            
            if selectedProblemSet?.id == problemSet.id {
                selectedProblemSet = problemSet
            }
            
            print("✅ Successfully updated ProblemSet with new subject: \(problemSet.subjectName)")
        } catch {
            self.error = error
            print("❌ Failed to update ProblemSet: \(error)")
        }
    }
    
    @MainActor
    func setSelectedProblemSet(_ problemSet: ProblemSet?) {
        guard selectedProblemSet?.id != problemSet?.id else { return }
        
        print("🔵 HomeViewModel - Setting selected problem set")
        
        // 상태 변경을 메인 스레드에서 한번에 처리
        DispatchQueue.main.async {
            self.selectedProblemSet = problemSet
            
            if let problemSet = problemSet {
                print("""
                ✅ ProblemSet set successfully:
                • ID: \(problemSet.id)
                • Questions: \(problemSet.questions.count)
                """)
            }
        }
    }
    
    @MainActor
    func clearSelectedProblemSet() {
        self.selectedProblemSet = nil
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

extension HomeViewModel {
    @MainActor
    func renameProblemSet(_ problemSet: ProblemSet, newName: String) async {
        // 빈 이름이나 공백만 있는 경우 처리 방지
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            print("❌ Cannot rename problem set: Name is empty")
            return
        }

        do {
            // 1. CoreData 업데이트
            try await coreDataService.updateProblemSet(problemSet, newName: trimmedName)
            
            await MainActor.run {
                // 2. 새로운 ProblemSet 인스턴스 생성
                let updatedSet = ProblemSet(
                    id: problemSet.id,
                    subject: problemSet.subject,
                    subjectType: problemSet.subjectType,
                    subjectId: problemSet.subjectId,
                    subjectName: problemSet.subjectName,
                    questions: problemSet.questions,
                    createdAt: problemSet.createdAt,
                    educationLevel: problemSet.educationLevel,
                    name: trimmedName  // trimmed된 이름 사용
                )
                
                // 3. problemSets 배열 업데이트
                if let index = self.problemSets.firstIndex(where: { $0.id == problemSet.id }) {
                    self.problemSets[index] = updatedSet
                }
                
                // 4. selectedProblemSet 업데이트
                if self.selectedProblemSet?.id == problemSet.id {
                    self.selectedProblemSet = updatedSet
                }
            }
            
            print("""
            ✅ Problem Set renamed successfully:
            • ID: \(problemSet.id)
            • Old Name: \(problemSet.name)
            • New Name: \(trimmedName)
            • Memory Update: Success
            """)
        } catch {
            print("❌ Failed to rename problem set: \(error)")
        }
    }
    
    @MainActor
    func deleteProblemSet(_ problemSet: ProblemSet) async {
        do {
            try await coreDataService.deleteProblemSet(problemSet)
            problemSets.removeAll { $0.id == problemSet.id }
            
            if selectedProblemSet?.id == problemSet.id {
                selectedProblemSet = nil
            }
            
            print("""
            ✅ Problem Set deleted:
            • ID: \(problemSet.id)
            • Name: \(problemSet.name)
            """)
        } catch {
            self.error = error
            print("❌ Failed to delete problem set: \(error)")
        }
    }
}
