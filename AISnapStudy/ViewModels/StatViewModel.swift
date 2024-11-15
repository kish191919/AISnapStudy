import Foundation
import Combine
import CoreData

@MainActor
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
    @Published var selectedTab: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext
    private let calendar = Calendar.current
    private var homeViewModel: HomeViewModel?
    private var studyViewModel: StudyViewModel?
    
    init(context: NSManagedObjectContext,
         homeViewModel: HomeViewModel? = nil,
         studyViewModel: StudyViewModel? = nil) {
        self.context = context
        self.homeViewModel = homeViewModel
        self.studyViewModel = studyViewModel
        loadStats()
    }
    
    func setHomeViewModel(_ viewModel: HomeViewModel) {
        self.homeViewModel = viewModel
    }
    
    func logCurrentQuestionState() {
        if let studyViewModel = homeViewModel?.studyViewModel, let question = studyViewModel.currentQuestion {
            print("🔄 Study View update initiated - currentQuestion: \(question.question), currentIndex: \(studyViewModel.currentIndex)")
        } else {
            print("🔄 Study View update initiated - No current question loaded, currentIndex: \(homeViewModel?.studyViewModel?.currentIndex ?? -1)")
        }
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
        totalQuestions = sessions.reduce(0) { total, session in
            total + (session.questions?.count ?? 0)
        }
        
        let totalCorrect = sessions.reduce(0) { total, session in
            total + (session.questions?.filter { ($0 as? CDQuestion)?.isCorrect == true }.count ?? 0)
        }
        
        averageScore = totalQuestions > 0 ? (Double(totalCorrect) / Double(totalQuestions)) * 100 : 0
        correctAnswers = totalCorrect
        completedQuestions = totalQuestions
        totalPoints = completedQuestions * 10
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
    
    func resetProgress() {
            print("🔄 Starting resetProgress...")
            correctAnswers = 0
            completedQuestions = 0
            accuracyRate = 0
            
            // HomeViewModel을 통해 StudyViewModel에 접근
            guard let homeVM = homeViewModel else {
                print("❌ homeViewModel is nil in resetProgress")
                return
            }
            
            guard let studyVM = homeVM.studyViewModel else {
                print("❌ studyViewModel is nil in resetProgress")
                return
            }
            
            guard let currentProblemSet = homeVM.selectedProblemSet else {
                print("❌ No selected problem set found")
                return
            }
            
            Task {
                print("🔄 Resetting study state...")
                await studyVM.resetState()
                
                await MainActor.run {
                    print("🔄 Loading questions...")
                    studyVM.loadQuestions(currentProblemSet.questions)
                    
                    print("""
                    ✅ Reset complete:
                    • ProblemSet: \(currentProblemSet.id)
                    • Questions Count: \(currentProblemSet.questions.count)
                    • Current Index: \(studyVM.currentIndex)
                    • Current Question: \(studyVM.currentQuestion?.question ?? "None")
                    """)
                }
            }
            
            loadStats()
        }
    

}
