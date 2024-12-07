
import Foundation

struct DailyProgress: Identifiable {
    let id = UUID()
    let date: Date
    var questionsCompleted: Int  // let -> var
    var correctAnswers: Int      // let -> var
    let totalTime: TimeInterval
    
    var accuracy: Double {
        guard questionsCompleted > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsCompleted) * 100
    }
    
    var day: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }
    
    init(date: Date, questionsCompleted: Int, correctAnswers: Int, totalTime: TimeInterval) {
           self.date = date
           self.questionsCompleted = questionsCompleted
           self.correctAnswers = correctAnswers
           self.totalTime = totalTime
       }
}
