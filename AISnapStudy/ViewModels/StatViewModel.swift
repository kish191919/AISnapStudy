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
    
    private weak var studyViewModel: StudyViewModel?
    private weak var homeViewModel: HomeViewModel?

    
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
    

    
    init(context: NSManagedObjectContext,
         homeViewModel: HomeViewModel? = nil,
         studyViewModel: StudyViewModel? = nil) {
        self.context = context
        self.homeViewModel = homeViewModel
        self.studyViewModel = studyViewModel
        
        // Move the loadStats() call to the end of the init method
        loadStats()
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
    
    func updateStats(correctAnswers: Int, totalQuestions: Int) {
        self.correctAnswers = correctAnswers
        self.completedQuestions = totalQuestions
        self.accuracyRate = totalQuestions > 0 ?
            (Double(correctAnswers) / Double(totalQuestions)) * 100 : 0
            
        print("""
        📊 Stats Updated:
        • Correct Answers: \(correctAnswers)
        • Total Score: \(correctAnswers * 10)
        • Accuracy Rate: \(accuracyRate)%
        """)
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
        
        // 오늘 날짜에 해당하는 세션만 필터링
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(
            format: "startTime >= %@ AND startTime < %@",
            today as NSDate,
            tomorrow as NSDate
        )

        do {
            let sessions = try context.fetch(request)
            calculateStats(from: sessions)
            
            // Weekly Progress 계산 추가
            calculateWeeklyProgress(from: sessions)
        } catch {
            print("Failed to fetch study sessions:", error)
        }
        
        isLoading = false
    }
    
    private func calculateWeeklyProgress(from sessions: [CDStudySession]) {
        let calendar = Calendar.current
        let today = Date()
        // 일주일 전 날짜 계산
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        
        // 빈 진행 상황으로 초기화
        var progress: [DailyProgress] = []
        
        // 지난 7일 동안의 날짜 생성
        for dayOffset in 0...6 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: weekAgo)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // 해당 날짜의 세션 필터링
            let daysSessions = sessions.filter { session in
                guard let sessionTime = session.startTime else { return false }
                return sessionTime >= dayStart && sessionTime < dayEnd
            }
            
            // 해당 날짜의 통계 계산
            let questionsCompleted = daysSessions.reduce(0) { sum, session in
                sum + (session.questions?.count ?? 0)
            }
            
            let correctAnswers = daysSessions.reduce(0) { sum, session in
                sum + (session.questions?.filter { ($0 as? CDQuestion)?.isCorrect == true }.count ?? 0)
            }
            
            let totalTime = daysSessions.reduce(0.0) { sum, session in
                guard let start = session.startTime,
                      let end = session.endTime else { return sum }
                return sum + end.timeIntervalSince(start)
            }
            
            // 진행 상황 추가
            progress.append(DailyProgress(
                date: date,
                questionsCompleted: questionsCompleted,
                correctAnswers: correctAnswers,
                totalTime: totalTime
            ))
        }
        
        weeklyProgress = progress
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
            totalPoints = 0  // 점수 초기화
            
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
            guard let homeVM = homeViewModel,
                  let studyVM = homeVM.studyViewModel,
                  let currentProblemSet = homeVM.selectedProblemSet else {
                print("❌ Required view models not found")
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

                        • Total Questions: \(currentProblemSet.questions.count)
                        """)
                    }
                }
            }
        }
