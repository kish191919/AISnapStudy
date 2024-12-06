
import Foundation
import SwiftUI
import Combine

@MainActor
class DetailedStatsViewModel: ObservableObject {
    @Published private(set) var dailyStats: [DailyStats] = []
    @Published private(set) var streakInfo: StreakInfo
    @Published private(set) var monthlyData: [Date: [DailyStats]] = [:]
    
    private let calendar = Calendar.current
    
    init() {
        self.streakInfo = StreakInfo(currentStreak: 0, longestStreak: 0, lastActiveDate: Date())
        loadStats()
    }
    
    func loadStats() {
        // Load saved stats from UserDefaults or CoreData
    }
    
    func updateDailyStats(correctAnswers: Int, totalQuestions: Int) {
        let today = Date()
        let newStats = DailyStats(
            id: UUID(), // UUID().uuidString 대신 UUID() 사용
            date: today,
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            wrongAnswers: totalQuestions - correctAnswers,
            timeSpent: 0  // 기본값 사용
        )
        
        dailyStats.append(newStats)
        updateStreak(date: today)
        updateMonthlyData()
    }
    
    private func updateStreak(date: Date) {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!
        
        if calendar.isDate(date, inSameDayAs: streakInfo.lastActiveDate) {
            // Same day, no streak update needed
            return
        } else if calendar.isDate(yesterday, inSameDayAs: streakInfo.lastActiveDate) {
            // Consecutive day
            let newStreak = streakInfo.currentStreak + 1
            streakInfo = StreakInfo(
                currentStreak: newStreak,
                longestStreak: max(newStreak, streakInfo.longestStreak),
                lastActiveDate: date
            )
        } else {
            // Streak broken
            streakInfo = StreakInfo(
                currentStreak: 1,
                longestStreak: streakInfo.longestStreak,
                lastActiveDate: date
            )
        }
    }
    
    private func updateMonthlyData() {
        monthlyData = Dictionary(grouping: dailyStats) { stats in
            calendar.startOfMonth(for: stats.date)
        }
    }
}

