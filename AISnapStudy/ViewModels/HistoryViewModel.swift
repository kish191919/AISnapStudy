//  ViewModels/HistoryViewModel.swift
import Foundation

class HistoryViewModel: ObservableObject {
    @Published var studySessions: [StudySession] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let storageService: StorageService
    
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
        loadStudySessions()
    }
    
    func loadStudySessions() {
        isLoading = true
        
        do {
            studySessions = try storageService.getStudySessions()
            // 최신 세션이 위로 오도록 정렬
            studySessions.sort { $0.startTime > $1.startTime }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func deleteSession(_ session: StudySession) {
        if let index = studySessions.firstIndex(where: { $0.id == session.id }) {
            let deletedSession = studySessions.remove(at: index)
            
            // 스토리지에서도 삭제
            Task {
                do {
                    try await Task.detached {
                        try self.storageService.deleteStudySession(session)
                    }.value
                } catch {
                    // UI 업데이트는 메인 스레드에서
                    await MainActor.run {
                        self.error = error
                        // 삭제 실패 시 배열에 다시 추가
                        self.studySessions.insert(deletedSession, at: index)
                    }
                }
            }
        }
    }
}
