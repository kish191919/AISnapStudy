import Foundation
import Combine
import CoreData

class StatViewModel: ObservableObject {
    @Published var weeklyProgress: [DailyProgress] = []
    @Published var totalQuestions = 0
    @Published var averageScore: Double = 0.0
    @Published var languageArtsProgress: Double = 0.0
    @Published var mathProgress: Double = 0.0
    @Published var streak: Int = 0
    @Published var totalPoints: Int = 0
    @Published var completedQuestions: Int = 0
    @Published var accuracyRate: Double = 0.0
    @Published var correctAnswers: Int = 0
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext
    private let calendar = Calendar.current

    init(context: NSManagedObjectContext) {
        self.context = context
        loadStats()
    }

    func loadStats() {
        isLoading = true
        let request: NSFetchRequest<CDStudySession> = CDStudySession.fetchRequest()
        
        do {
            let sessions = try context.fetch(request)
            calculateStats(from: sessions)
        } catch {
            print("Failed to fetch study sessions:", error)
        }
        
        isLoading = false
    }

    private func calculateStats(from sessions: [CDStudySession]) {
        // 총 질문 수를 각 세션의 질문 수를 합산하여 계산
        totalQuestions = sessions.reduce(0) { total, session in
            total + (session.questions?.count ?? 0)
        }
        
        // 총 정답 수를 isCorrect 속성을 기준으로 계산
        let totalCorrect = sessions.reduce(0) { total, session in
            total + (session.questions?.filter { ($0 as? CDQuestion)?.isCorrect == true }.count ?? 0)
        }
        
        averageScore = totalQuestions > 0 ? (Double(totalCorrect) / Double(totalQuestions)) * 100 : 0
        correctAnswers = totalCorrect
        completedQuestions = totalQuestions
        totalPoints = completedQuestions * 10 // 각 문제당 10포인트
        
        accuracyRate = completedQuestions > 0 ? (Double(correctAnswers) / Double(completedQuestions)) * 100 : 0
        
        streak = calculateStreak(from: sessions)
    }

    private func calculateStreak(from sessions: [CDStudySession]) -> Int {
        let sortedSessions = sessions.compactMap { $0.endTime }.sorted(by: { $0 > $1 })
        
        var currentStreak = 0
        var streakDate = Date()
        
        for date in sortedSessions {
            if calendar.isDate(date, inSameDayAs: streakDate) || calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: streakDate)!) {
                currentStreak += 1
                streakDate = date
            } else {
                break
            }
        }
        
        return currentStreak
    }
    
    func formatProgress(_ progress: Double) -> String {
        return String(format: "%.1f%%", progress)
    }
}
