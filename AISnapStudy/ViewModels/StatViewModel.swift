// ViewModels/StatViewModel.swift
import Foundation
import Combine

import Foundation
import Combine

class StatViewModel: ObservableObject {
    @Published var weeklyProgress: [DailyProgress] = []
    @Published var totalQuestions = 0
    @Published var averageScore: Double = 0.0
    @Published var languageArtsProgress: Double = 0.0
    @Published var mathProgress: Double = 0.0
    @Published var error: Error?
    @Published var isLoading = false
    
    private let storageService: StorageService
    private let calendar = Calendar.current
    
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
        loadStats()
    }
    
    func loadStats() {
        isLoading = true
        
        do {
            let sessions = try storageService.getStudySessions()
            calculateStats(from: sessions)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func calculateStats(from sessions: [StudySession]) {
        // Calculate total questions and average score
        totalQuestions = sessions.count
        
        let totalCorrect = sessions.reduce(0) { sum, session in
            let correctCount = session.answers.filter {
                $0.value == session.correctAnswers[$0.key]
            }.count
            return sum + correctCount
        }
        
        averageScore = totalQuestions > 0 ?
            (Double(totalCorrect) / Double(totalQuestions)) * 100 : 0
        
        // Calculate subject-specific progress
        let languageArtsSessions = sessions.filter {
            $0.problemSet.subject == .languageArts
        }
        let mathSessions = sessions.filter {
            $0.problemSet.subject == .math
        }
        
        languageArtsProgress = calculateProgress(for: languageArtsSessions)
        mathProgress = calculateProgress(for: mathSessions)
        
        // Calculate weekly progress
        weeklyProgress = calculateWeeklyProgress(from: sessions)
    }
    
    private func calculateProgress(for sessions: [StudySession]) -> Double {
        guard !sessions.isEmpty else { return 0 }
        
        let totalCorrect = sessions.reduce(0) { sum, session in
            let correctCount = session.answers.filter {
                $0.value == session.correctAnswers[$0.key]
            }.count
            return sum + correctCount
        }
        
        return Double(totalCorrect) / Double(sessions.count) * 100
    }
    
    private func calculateWeeklyProgress(from sessions: [StudySession]) -> [DailyProgress] {
        let today = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else {
            return []
        }
        
        // Create date range for the past week
        let dates = (0...6).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekAgo)
        }
        
        // Group sessions by date
        return dates.map { date in
            let daysSessions = sessions.filter { session in
                calendar.isDate(session.startTime, inSameDayAs: date)
            }
            
            let questionsCompleted = daysSessions.reduce(0) {
                $0 + $1.answers.count
            }
            let correctAnswers = daysSessions.reduce(0) { sum, session in
                sum + session.answers.filter {
                    $0.value == session.correctAnswers[$0.key]
                }.count
            }
            let totalTime = daysSessions.reduce(0) { sum, session in
                sum + (session.duration ?? 0)
            }
            
            return DailyProgress(
                date: date,
                questionsCompleted: questionsCompleted,
                correctAnswers: correctAnswers,
                totalTime: totalTime
            )
        }
    }
    
    // Helper method to format progress percentage
    func formatProgress(_ progress: Double) -> String {
        return String(format: "%.1f%%", progress)
    }
}
