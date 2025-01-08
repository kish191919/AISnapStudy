import SwiftUI

struct CalendarStatsView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedMonth = Date()
    let monthlyData: [Date: [DailyStats]]
    private let calendar = Calendar.current
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) { // spacing을 0으로 설정하여 간격 최소화
                    // Calendar Section
                    VStack(spacing: 12) {
                        HStack {
                            Button(action: previousMonth) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: horizontalSizeClass == .regular ? 28 : 20))
                            }
                            
                            Spacer()
                            Text(monthString)
                                .font(.system(size: horizontalSizeClass == .regular ? 32 : 22, weight: .bold))
                            Spacer()
                            
                            Button(action: nextMonth) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: horizontalSizeClass == .regular ? 28 : 20))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Calendar Grid
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                            spacing: 4
                        ) {
                            // Weekday Headers
                            ForEach(daysInWeek, id: \.self) { day in
                                Text(day)
                                    .font(.system(size: horizontalSizeClass == .regular ? 22 : 14))
                                    .foregroundColor(.gray)
                            }
                            
                            // Date Cells
                            ForEach(calendarDays, id: \.id) { calendarDay in
                                if let stats = statsFor(date: calendarDay.date) {
                                    DayCellView(
                                        date: calendarDay.date,
                                        progress: convertToDailyProgress(stats),
                                        size: (geometry.size.width - 48) / 7, // 전체 너비에서 패딩을 뺀 값을 7로 나눔
                                        fontSize: horizontalSizeClass == .regular ? 24 : 16
                                    )
                                } else {
                                    Text(String(calendar.component(.day, from: calendarDay.date)))
                                        .font(.system(size: horizontalSizeClass == .regular ? 24 : 16))
                                        .foregroundColor(.secondary)
                                        .frame(
                                            width: (geometry.size.width - 48) / 7,
                                            height: (geometry.size.width - 48) / 7
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                    .cornerRadius(16)
                    .padding(.horizontal, 8)
                    
                    // Progress Circles with minimal spacing
                    VStack(spacing: 0) {
                        HStack(spacing: geometry.size.width * 0.08) { // 화면 너비의 8%만 간격으로 사용
                            CircleProgressView(
                                progress: calculateTodayProgress(),
                                title: "Today's Accuracy",
                                total: todayStats?.questionsCompleted ?? 0,
                                correct: todayStats?.correctAnswers ?? 0,
                                incorrect: (todayStats?.questionsCompleted ?? 0) - (todayStats?.correctAnswers ?? 0),
                                size: min(geometry.size.width * 0.4, 300) // 화면 너비의 40%로 증가
                            )
                            
                            CircleProgressView(
                                progress: calculateMonthlyProgress(),
                                title: "Monthly Accuracy",
                                total: monthlyStats.total,
                                correct: monthlyStats.correct,
                                incorrect: monthlyStats.incorrect,
                                size: min(geometry.size.width * 0.4, 300) // 화면 너비의 40%로 증가
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20) // 달력과의 간격을 20으로 축소
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var calendarDays: [CalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end) else {
            return []
        }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        let dates = calendar.generateDates(for: dateInterval, matching: DateComponents(hour: 0))
        
        return dates.enumerated().map { CalendarDay(id: $0, date: $1) }
    }
    
    private func convertToDailyProgress(_ stats: DailyStats) -> DailyProgress {
        return DailyProgress(
            date: stats.date,
            questionsCompleted: stats.totalQuestions,
            correctAnswers: stats.correctAnswers,
            totalTime: 0  // 시간 데이터가 없다면 0으로 설정
        )
    }

    private func calculateTodayProgress() -> Double {
        guard let stats = todayStats,
              stats.questionsCompleted > 0 else { return 0 }
        return Double(stats.correctAnswers) / Double(stats.questionsCompleted)
    }
    
    private func calculateMonthlyProgress() -> Double {
        guard monthlyStats.total > 0 else { return 0 }
        return Double(monthlyStats.correct) / Double(monthlyStats.total)
    }
    
    private var todayStats: DailyProgress? {
        let today = Date()
        return monthlyData.values
            .flatMap { $0 }
            .map { convertToDailyProgress($0) }
            .first { calendar.isDate($0.date, inSameDayAs: today) }
    }
    
    private var monthlyStats: (total: Int, correct: Int, incorrect: Int) {
        let stats = monthlyData.values
            .flatMap { $0 }
        let total = stats.reduce(0) { $0 + $1.totalQuestions }
        let correct = stats.reduce(0) { $0 + $1.correctAnswers }
        return (total, correct, total - correct)
    }
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end) else {
            return []
        }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDates(for: dateInterval, matching: DateComponents(hour: 0))
    }
    
    private func statsFor(date: Date) -> DailyStats? {
        let monthRange = calendar.monthDateRange(for: selectedMonth)
        guard let stats = monthlyData[monthRange.start] else { return nil }
        return stats.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func previousMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }
    
    private func nextMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }
}
