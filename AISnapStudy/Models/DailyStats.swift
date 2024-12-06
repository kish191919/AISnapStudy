

import Foundation

struct DailyStats: Identifiable, Codable {
    let id: UUID
    let date: Date
    let totalQuestions: Int
    let correctAnswers: Int
    let wrongAnswers: Int
    let timeSpent: TimeInterval
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    // 초기화자를 수정
    init(
        id: UUID = UUID(),
        date: Date,
        totalQuestions: Int,
        correctAnswers: Int,
        wrongAnswers: Int,
        timeSpent: TimeInterval = 0
    ) {
        self.id = id
        self.date = date
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.wrongAnswers = wrongAnswers
        self.timeSpent = timeSpent
    }
}
