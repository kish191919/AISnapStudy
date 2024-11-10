// Models/DailyProgress.swift
import Foundation

struct DailyProgress: Identifiable {
    let id = UUID()
    let date: Date
    let day: String          // "Mon", "Tue", etc.
    let questionsCompleted: Int
    let correctAnswers: Int
    let totalTime: TimeInterval
    
    var accuracy: Double {
        guard questionsCompleted > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsCompleted) * 100
    }
    
    init(date: Date, questionsCompleted: Int, correctAnswers: Int, totalTime: TimeInterval) {
        self.date = date
        self.day = date.formatted(.dateTime.weekday(.abbreviated))
        self.questionsCompleted = questionsCompleted
        self.correctAnswers = correctAnswers
        self.totalTime = totalTime
    }
}
