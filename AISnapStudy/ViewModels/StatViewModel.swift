import Foundation
import Combine
import CoreData

@MainActor
class StatViewModel: ObservableObject {
    @Published var streak: Int = 0
    @Published var correctAnswers: Int = 0 {
        didSet {
            // 점수가 변경될 때마다 출력되는 디버그 로그
            print("📊 StatViewModel score updated: \(correctAnswers * 10) points")
        }
    }
    @Published var completedQuestions: Int = 0
    @Published var accuracyRate: Double = 0.0
    @Published var isLoading = false
    private var todaysSessionStats: (questions: Int, correct: Int) = (0, 0)
    private var existingStats: (questions: Int, correct: Int) = (0, 0)
    
    private weak var studyViewModel: StudyViewModel?
    private weak var homeViewModel: HomeViewModel?
    private var todayTotalQuestions: Int = 0
    private var todayCorrectAnswers: Int = 0

    
    @Published var totalPoints: Int = 0      // 현재 세션의 점수
    @Published var weeklyProgress: [DailyProgress] = []
    @Published var totalQuestions = 0
    @Published var averageScore: Double = 0.0
    @Published var languageArtsProgress: Double = 0.0
    @Published var mathProgress: Double = 0.0
    @Published var selectedTab: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext
    private let calendar = Calendar.current
    
    private var sessionStats: SessionStats = .init() // 새로 추가

    struct SessionStats {
        var completedQuestions: Int = 0
        var correctAnswers: Int = 0
        var startTime: Date = Date()
    }
    

    
    init(context: NSManagedObjectContext,
         homeViewModel: HomeViewModel? = nil,
         studyViewModel: StudyViewModel? = nil) {
        self.context = context
        self.homeViewModel = homeViewModel
        self.studyViewModel = studyViewModel
        
        // Move the loadStats() call to the end of the init method
        loadStats()
        setupObservers()
    }
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStudyProgressUpdate),
            name: .studyProgressDidUpdate,
            object: nil
        )
    }
    
    @objc private func handleStudyProgressUpdate(_ notification: Notification) {
        guard let currentIndex = notification.userInfo?["currentIndex"] as? Int,
              let correctAnswers = notification.userInfo?["correctAnswers"] as? Int else {
            return
        }
        
        // 새로운 문제가 완료될 때마다 통계 업데이트
        let addedQuestions = 1  // 한 문제씩 추가
        let addedCorrect = correctAnswers - self.correctAnswers  // 새로운 정답만큼만 추가
        
        updateStats(
            correctAnswers: addedCorrect,
            totalQuestions: addedQuestions,
            isNewSession: false
        )
        
        self.correctAnswers = correctAnswers
    }
    
    var currentSessionScore: Int {
        return correctAnswers * 10  // 계산 속성으로 변경
    }
    
    // StudyViewModel 설정 메서드
    func setStudyViewModel(_ viewModel: StudyViewModel?) {
        self.studyViewModel = viewModel
        print("📱 StudyViewModel connected to StatViewModel")
    }

    
    func updateScore() {
        if let studyVM = studyViewModel {
            // correctAnswers 값을 업데이트
            self.correctAnswers = studyVM.correctAnswers
            self.totalQuestions = studyVM.totalQuestions
            // 디버그를 위한 로그
            print("📊 Score Updated - Correct: \(correctAnswers), Total: \(totalQuestions), Score: \(currentSessionScore)")
        }
    }
    
    func updateStats(correctAnswers: Int, totalQuestions: Int, isNewSession: Bool = false) {
         let today = Date()
         
         // 기존 통계를 찾거나 새로 생성
         if let existingIndex = weeklyProgress.firstIndex(where: {
             Calendar.current.isDate($0.date, inSameDayAs: today)
         }) {
             let existingProgress = weeklyProgress[existingIndex]
             let updatedQuestions = isNewSession ?
                 existingProgress.questionsCompleted :
                 existingProgress.questionsCompleted + totalQuestions
             let updatedCorrect = isNewSession ?
                 existingProgress.correctAnswers :
                 existingProgress.correctAnswers + correctAnswers
                 
             weeklyProgress[existingIndex] = DailyProgress(
                 date: today,
                 questionsCompleted: updatedQuestions,
                 correctAnswers: updatedCorrect,
                 totalTime: existingProgress.totalTime
             )
         } else {
             weeklyProgress.append(DailyProgress(
                 date: today,
                 questionsCompleted: totalQuestions,
                 correctAnswers: correctAnswers,
                 totalTime: 0.0
             ))
         }
         
         print("""
         📊 Stats updated:
         • Added Questions: \(totalQuestions)
         • Added Correct: \(correctAnswers)
         • Total Questions: \(weeklyProgress.last?.questionsCompleted ?? 0)
         • New Session: \(isNewSession)
         """)
         
         objectWillChange.send()
     }
    
    private func updateWeeklyProgress() {
        let today = Date()
        if let index = weeklyProgress.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            let updatedProgress = DailyProgress(
                date: today,
                questionsCompleted: completedQuestions,
                correctAnswers: correctAnswers,
                totalTime: weeklyProgress[index].totalTime
            )
            weeklyProgress[index] = updatedProgress
        } else {
            let newProgress = DailyProgress(
                date: today,
                questionsCompleted: completedQuestions,
                correctAnswers: correctAnswers,
                totalTime: 0.0  // New entry starts with 0 time
            )
            weeklyProgress.append(newProgress)
        }
        
        objectWillChange.send()
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
        print("📊 Starting stats loading...")
        isLoading = true
        let request: NSFetchRequest<CDStudySession> = CDStudySession.fetchRequest()
        
        do {
            let sessions = try context.fetch(request)
            calculateStats(from: sessions)
            calculateWeeklyProgress(from: sessions)
            
            if let todayStats = weeklyProgress.last {
                existingStats = (todayStats.questionsCompleted, todayStats.correctAnswers)
                
                DispatchQueue.main.async { [weak self] in
                    self?.completedQuestions = todayStats.questionsCompleted
                    self?.correctAnswers = todayStats.correctAnswers
                    self?.accuracyRate = todayStats.accuracy
                    print("""
                    📊 Stats updated from weekly progress:
                    • Questions: \(todayStats.questionsCompleted)
                    • Correct: \(todayStats.correctAnswers)
                    • Accuracy: \(todayStats.accuracy)%
                    """)
                }
            }
        } catch {
            print("❌ Failed to fetch study sessions: \(error)")
        }
        
        isLoading = false
    }
    
    
    private func calculateWeeklyProgress(from sessions: [CDStudySession]) {
        print("📊 Starting weekly progress calculation...")
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        
        var progress: [DailyProgress] = []
        
        for dayOffset in 0...6 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: weekAgo)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Filter sessions for current day
            let daysSessions = sessions.filter { session in
                guard let sessionTime = session.startTime else { return false }
                return calendar.isDate(sessionTime, inSameDayAs: date)
            }
            
            let questionsCompleted = daysSessions.reduce(0) { sum, session in
                sum + (session.questions?.count ?? 0)
            }
            
            let correctAnswers = daysSessions.reduce(0) { sum, session in
                sum + ((session.questions?.allObjects as? [CDQuestion])?.filter { $0.isCorrect }.count ?? 0)
            }
            
            let totalTime = daysSessions.reduce(0.0) { sum, session in
                guard let start = session.startTime,
                      let end = session.endTime else { return sum }
                return sum + end.timeIntervalSince(start)
            }
            
            progress.append(DailyProgress(
                date: date,
                questionsCompleted: questionsCompleted,
                correctAnswers: correctAnswers,
                totalTime: totalTime
            ))
            
            // Log daily statistics
            print("""
            📊 Daily Stats for \(date):
            • Sessions: \(daysSessions.count)
            • Questions: \(questionsCompleted)
            • Correct: \(correctAnswers)
            """)
        }
        
        weeklyProgress = progress
    }
    

    private func calculateStats(from sessions: [CDStudySession]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let todaySessions = sessions.filter { session in
            guard let sessionTime = session.startTime else { return false }
            return calendar.isDate(sessionTime, inSameDayAs: today)
        }
        
        // 이전 세션 통계에 새로운 세션 통계 추가
        let newCompletedQuestions = todaySessions.reduce(0) { total, session in
            total + (session.questions?.count ?? 0)
        }
        let newCorrectAnswers = todaySessions.reduce(0) { total, session in
            total + ((session.questions?.allObjects as? [CDQuestion])?.filter { $0.isCorrect }.count ?? 0)
        }
        
        // Calculate today's statistics
        let totalCompletedQuestions = todaySessions.reduce(0) { total, session in
            total + (session.questions?.count ?? 0)
        }
        
        let totalCorrectAnswers = todaySessions.reduce(0) { total, session in
            total + ((session.questions?.allObjects as? [CDQuestion])?.filter { $0.isCorrect }.count ?? 0)
        }
        
        // Calculate accuracy rate
        let calculatedAccuracyRate = totalCompletedQuestions > 0 ?
            (Double(totalCorrectAnswers) / Double(totalCompletedQuestions)) * 100 : 0
        
        // 값 업데이트 후 명시적으로 UI 업데이트
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.objectWillChange.send()
            self.completedQuestions = newCompletedQuestions
            self.correctAnswers = newCorrectAnswers
            self.accuracyRate = self.completedQuestions > 0 ?
                (Double(self.correctAnswers) / Double(self.completedQuestions)) * 100 : 0
        }
        
        print("""
        📊 Today's Stats Calculated:
        • Previous Questions: \(todaysSessionStats.questions)
        • New Total Questions: \(completedQuestions)
        • Correct Answers: \(correctAnswers)
        • Accuracy Rate: \(accuracyRate)%
        """)
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
        
        // 현재까지의 통계를 저장
        let previousStats = (
            questions: completedQuestions,
            correct: correctAnswers
        )
        
        guard let homeVM = homeViewModel,
              let studyVM = homeVM.studyViewModel,
              let currentProblemSet = homeVM.selectedProblemSet else {
            print("❌ Required view models not found")
            return
        }
        
        Task {
            print("🔄 Resetting study state...")
            await studyVM.resetState()
            
            // 통계를 누적하여 업데이트
            updateStats(
                correctAnswers: previousStats.correct,
                totalQuestions: previousStats.questions,
                isNewSession: true  // 새로운 세션임을 표시
            )
            
            await MainActor.run {
                studyVM.loadQuestions(currentProblemSet.questions)
                
                print("""
                ✅ Reset complete:
                • Previous Questions: \(previousStats.questions)
                • Previous Correct: \(previousStats.correct)
                • Total Questions: \(completedQuestions)
                • New Session Questions: \(currentProblemSet.questions.count)
                """)
            }
        }
    }
}

extension Notification.Name {
    static let studyProgressDidUpdate = Notification.Name("studyProgressDidUpdate")
}
