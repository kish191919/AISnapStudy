import SwiftUI



struct CalendarStatsView: View {
    @State private var selectedMonth = Date()  // 내부에서 상태 관리
    let monthlyData: [Date: [DailyStats]]
    private let calendar = Calendar.current
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
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
    
    var body: some View {
        VStack {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                
                Text(monthString)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.bottom)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                 // 요일 헤더
                 ForEach(daysInWeek, id: \.self) { day in
                     Text(day)
                         .font(.caption)
                         .foregroundColor(.secondary)
                 }
                 
                 // 날짜 그리드
                 ForEach(calendarDays, id: \.id) { calendarDay in
                     if let stats = statsFor(date: calendarDay.date) {
                         DayCellView(
                             date: calendarDay.date,
                             progress: convertToDailyProgress(stats)
                         )
                     } else {
                         Text(String(calendar.component(.day, from: calendarDay.date)))
                             .font(.caption)
                             .foregroundColor(.secondary)
                             .frame(height: 35)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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


