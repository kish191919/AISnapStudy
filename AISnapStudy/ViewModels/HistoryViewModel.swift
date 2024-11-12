
import Foundation

class HistoryViewModel: ObservableObject {
    @Published var studySessions: [StudySession] = []
    @Published var problemSets: [ProblemSet] = []  // 추가
    @Published var isLoading = false
    @Published var error: Error?
    
    private let storageService: StorageService
    private let coreDataService: CoreDataService
    
    init(storageService: StorageService = StorageService(),
         coreDataService: CoreDataService = .shared) {
        self.storageService = storageService
        self.coreDataService = coreDataService
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        do {
            // Load study sessions
            studySessions = try storageService.getStudySessions()
            studySessions.sort { $0.startTime > $1.startTime }
            
            // Load problem sets
            problemSets = try coreDataService.fetchProblemSets()
            
            print("""
            📚 History Data Loaded:
            • Study Sessions: \(studySessions.count)
            • Problem Sets: \(problemSets.count)
            """)
            
            // 각 problemSet의 제목을 출력하여 데이터 로드를 확인
            for problemSet in problemSets {
                print("Loaded Problem Set - Title: \(problemSet.title)")
            }
            
        } catch {
            self.error = error
            print("❌ Failed to load history data: \(error)")
        }
        
        isLoading = false
    }

    
    func deleteSession(_ session: StudySession) {
        if let index = studySessions.firstIndex(where: { $0.id == session.id }) {
            let deletedSession = studySessions.remove(at: index)
            
            Task {
                do {
                    try await Task.detached {
                        try self.storageService.deleteStudySession(session)
                    }.value
                } catch {
                    await MainActor.run {
                        self.error = error
                        self.studySessions.insert(deletedSession, at: index)
                    }
                }
            }
        }
    }
    
    func refreshData() {
        loadData()
    }
}
