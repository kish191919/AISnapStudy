
import Foundation

struct DailyProgress: Identifiable {
    let id = UUID()
    let date: Date
    var questionsCompleted: Int
    var correctAnswers: Int
    let totalTime: TimeInterval
    
    var accuracy: Double {
        guard questionsCompleted > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsCompleted) * 100
    }
    
    var week: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd" // 월/일 형식
        return formatter.string(from: date)
    }
    
    init(date: Date, questionsCompleted: Int, correctAnswers: Int, totalTime: TimeInterval) {
        self.date = date
        self.questionsCompleted = questionsCompleted
        self.correctAnswers = correctAnswers
        self.totalTime = totalTime
    }
}
