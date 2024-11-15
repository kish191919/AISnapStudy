
import Foundation

import Foundation

@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var studySessions: [StudySession] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var problemSets: [ProblemSet] = []
    @Published private(set) var savedQuestions: [Question] = []

    // MARK: - Dependencies
    private let storageService: StorageService
    private weak var homeViewModel: HomeViewModel?
    
    // MARK: - Initialization
    init(storageService: StorageService = StorageService(),
         homeViewModel: HomeViewModel? = nil) {
        self.storageService = storageService
        self.homeViewModel = homeViewModel
        loadStudySessions()
    }
    
    // MARK: - Data Loading
    private func loadStudySessions() {
        isLoading = true
        
        do {
            studySessions = try storageService.getStudySessions()
            studySessions.sort { $0.startTime > $1.startTime }
            
            // Update problemSets and savedQuestions from homeViewModel
            if let homeVM = homeViewModel {
                problemSets = homeVM.problemSets
                savedQuestions = homeVM.savedQuestions
            }
            
            print("""
            📚 History Data Loaded:
            • Study Sessions: \(studySessions.count)
            • Problem Sets: \(problemSets.count)
            • Saved Questions: \(savedQuestions.count)
            """)
        } catch {
            self.error = error
            print("❌ Failed to load study sessions: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Session Management
    func deleteSession(_ session: StudySession) {
        guard let index = studySessions.firstIndex(where: { $0.id == session.id }) else {
            return
        }
        
        let deletedSession = studySessions.remove(at: index)
        
        Task {
            do {
                try await Task.detached {
                    try self.storageService.deleteStudySession(session)
                }.value
                print("✅ Successfully deleted study session: \(session.id)")
            } catch {
                await MainActor.run {
                    self.error = error
                    self.studySessions.insert(deletedSession, at: index)
                    print("❌ Failed to delete study session: \(error)")
                }
            }
        }
    }
    
    // MARK: - Data Refresh
    func refreshData() {
        loadStudySessions()
    }
    
    // MARK: - HomeViewModel Management
    func setHomeViewModel(_ viewModel: HomeViewModel) {
        self.homeViewModel = viewModel
        // Update data immediately when HomeViewModel is set
        problemSets = viewModel.problemSets
        savedQuestions = viewModel.savedQuestions
        print("📱 HomeViewModel reference set in HistoryViewModel")
    }
    
    // MARK: - Data Access Methods
    func getProblemSets() -> [ProblemSet] {
        problemSets
    }
    
    func getSavedQuestions() -> [Question] {
        savedQuestions
    }
}
