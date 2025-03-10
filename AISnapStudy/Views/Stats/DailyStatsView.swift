import SwiftUI
import Charts

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
}

struct DailyStatsView: View {
    @State private var currentMonthDate = Date()  // 추가된 상태 변수
    @ObservedObject var viewModel: StatViewModel
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var todayStats: DailyProgress? {
        let calendar = Calendar.current
        return viewModel.weeklyProgress.first {
            calendar.isDate($0.date, inSameDayAs: Date())
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                timePicker
                
                switch selectedTimeRange {
                case .week:
                    weeklyProgressChart
                case .month:
                    VStack(spacing: 10) {
                        // 월 이동 컨트롤
                        HStack {
                            Button(action: previousMonth) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .padding(.horizontal, 40) // 화살표 버튼 좌우 패딩 추가
                            }
                            
                            Text(monthYearString)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                            
                            Button(action: nextMonth) {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .padding(.horizontal, 40) // 화살표 버튼 좌우 패딩 추가
                            }
                        }
                        .padding(.horizontal)
                        
                        MonthCalendarView(
                            month: currentMonthDate,
                            monthlyData: viewModel.monthlyProgress
                        )
                    }
                }
                
                StatsCircleContainer(
                    todayStats: todayStats,
                    weeklyStats: viewModel.weeklyProgress,
                    monthlyProgress: viewModel.monthlyProgress,  // 추가
                    selectedTimeRange: selectedTimeRange,        // 추가
                    currentMonthDate: currentMonthDate
                )
            }
            .padding()
        }
        .navigationTitle("Daily Statistics")
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonthDate)
    }
    
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentMonthDate) {
            currentMonthDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentMonthDate) {
            currentMonthDate = newDate
        }
    }

    
    
    private var weeklyProgressChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Progress")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(viewModel.weeklyProgress) { progress in
                    BarMark(
                        x: .value("Day", progress.week),
                        y: .value("Questions", progress.questionsCompleted)
                    )
                    .position(by: .value("Type", "Total"))
                    .foregroundStyle(.blue.opacity(0.3))
                    
                    BarMark(
                        x: .value("Day", progress.week),
                        y: .value("Questions", progress.correctAnswers)
                    )
                    .position(by: .value("Type", "Correct"))
                    .foregroundStyle(.green)
                }
            }
            .frame(height: horizontalSizeClass == .regular ? 250 : 200)
            .padding(.horizontal, 20)
            .chartLegend(position: .top)
            .chartForegroundStyleScale([
                "Total": .blue.opacity(0.3),
                "Correct": .green
            ])
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var monthlyProgressChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Progress")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(viewModel.monthlyProgress) { progress in
                    BarMark(
                        x: .value("Day", progress.week),
                        y: .value("Questions", progress.questionsCompleted)
                    )
                    .position(by: .value("Type", "Total"))
                    .foregroundStyle(.blue.opacity(0.3))
                    
                    BarMark(
                        x: .value("Day", progress.week),
                        y: .value("Questions", progress.correctAnswers)
                    )
                    .position(by: .value("Type", "Correct"))
                    .foregroundStyle(.green)
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 20)
            .chartLegend(position: .top)
            .chartForegroundStyleScale([
                "Total": .blue.opacity(0.3),
                "Correct": .green
            ])
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var yearlyProgressChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Yearly Progress")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(viewModel.yearlyProgress) { progress in
                    BarMark(
                        x: .value("Month", progress.week),
                        y: .value("Questions", progress.questionsCompleted)
                    )
                    .position(by: .value("Type", "Total"))
                    .foregroundStyle(.blue.opacity(0.3))
                    
                    BarMark(
                        x: .value("Month", progress.week),
                        y: .value("Questions", progress.correctAnswers)
                    )
                    .position(by: .value("Type", "Correct"))
                    .foregroundStyle(.green)
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 20)
            .chartLegend(position: .top)
            .chartForegroundStyleScale([
                "Total": .blue.opacity(0.3),
                "Correct": .green
            ])
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var timePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .onChange(of: selectedTimeRange) { _ in
            let period: StatsPeriod = switch selectedTimeRange {
                case .week: .day
                case .month: .month
            }
            Task {
                await viewModel.loadStatsByPeriod(period)
            }
        }
    }
}

struct CalendarDay: Identifiable, Hashable {
    let id: Int
    let date: Date
    
    // Hashable 구현
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
    }
    
    static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.id == rhs.id && lhs.date == rhs.date
    }
}

struct MonthCalendarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let month: Date
    let monthlyData: [DailyProgress]
    private let calendar = Calendar.current
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // 아이패드에서 더 큰 셀 크기 사용
    private var cellSize: CGFloat {
        horizontalSizeClass == .regular ? 80 : 45
    }
    
    private var dayFontSize: CGFloat {
        horizontalSizeClass == .regular ? 18 : 12
    }
    
    private var dateFontSize: CGFloat {
        horizontalSizeClass == .regular ? 18 : 14
    }
    
    var body: some View {
        GeometryReader { geometry in
            let calendarWidth = geometry.size.width * 0.95 // 화면 너비의 95% 사용
            let cellWidth = (calendarWidth - 40) / 7
            let adjustedCellSize = min(cellSize, cellWidth)
            
            VStack(spacing: 8) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(adjustedCellSize), spacing: 4), count: 7),
                    spacing: 4
                ) {
                    // 요일 헤더
                    ForEach(daysInWeek, id: \.self) { day in
                        Text(day)
                            .font(.system(size: dayFontSize))
                            .foregroundColor(.gray)
                            .frame(width: adjustedCellSize)
                    }
                    
                    // 빈 셀 채우기
                    ForEach(0..<firstWeekdayOfMonth, id: \.self) { _ in
                        Color.clear
                            .frame(width: adjustedCellSize, height: adjustedCellSize)
                    }
                    
                    // 날짜 그리드
                    ForEach(calendarDays, id: \.id) { calendarDay in
                        if let progress = progressForDate(calendarDay.date),
                           progress.questionsCompleted > 0 {
                            DayCellView(
                                date: calendarDay.date,
                                progress: progress,
                                size: adjustedCellSize,
                                fontSize: dateFontSize
                            )
                        } else {
                            Text(String(calendar.component(.day, from: calendarDay.date)))
                                .font(.system(size: dateFontSize, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .frame(width: adjustedCellSize, height: adjustedCellSize)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .frame(width: calendarWidth)
            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
            .cornerRadius(16)
            .frame(maxWidth: .infinity)
        }
        .frame(height: horizontalSizeClass == .regular ? 450 : 270)
    }

    // 월의 첫 번째 날의 요일 (0 = 일요일, 6 = 토요일)
    private var firstWeekdayOfMonth: Int {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return 0
        }
        return calendar.component(.weekday, from: firstDay) - 1
    }
    
    private var calendarDays: [CalendarDay] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }
        
        return (1...range.count).map { day -> CalendarDay in
            let components = calendar.dateComponents([.year, .month], from: month)
            var newComponents = DateComponents()
            newComponents.year = components.year
            newComponents.month = components.month
            newComponents.day = day
            let date = calendar.date(from: newComponents) ?? month
            return CalendarDay(id: day, date: date)
        }
    }
    
    private func progressForDate(_ date: Date) -> DailyProgress? {
        monthlyData.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end) else {
            return []
        }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDates(for: dateInterval, matching: DateComponents(hour: 0))
    }
}


struct StatsCircleContainer: View {
    let todayStats: DailyProgress?
    let weeklyStats: [DailyProgress]
    let monthlyProgress: [DailyProgress]
    let selectedTimeRange: TimeRange
    let currentMonthDate: Date
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var containerSpacing: CGFloat {
        horizontalSizeClass == .regular ? 80 : 30
    }
    
    private var verticalSpacing: CGFloat {
        horizontalSizeClass == .regular ? 0 : 0
    }
    
    private var circleSize: CGFloat {
        horizontalSizeClass == .regular ? 200 : 150
    }

    
    private var monthlyStats: (total: Int, correct: Int, incorrect: Int) {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentMonthDate)
        let currentYear = calendar.component(.year, from: currentMonthDate)
        
        let thisMonthProgress = monthlyProgress.filter { progress in
            let progressMonth = calendar.component(.month, from: progress.date)
            let progressYear = calendar.component(.year, from: progress.date)
            return progressMonth == currentMonth && progressYear == currentYear
        }
        
        let total = thisMonthProgress.reduce(0) { $0 + $1.questionsCompleted }
        let correct = thisMonthProgress.reduce(0) { $0 + $1.correctAnswers }
        return (total, correct, total - correct)
    }
    
    var body: some View {
        VStack(spacing: verticalSpacing) {
            HStack(spacing: containerSpacing) {
                CircleProgressView(
                    progress: Double(todayStats?.correctAnswers ?? 0) / Double(max(1, todayStats?.questionsCompleted ?? 1)),
                    title: "Today's Accuracy",
                    total: todayStats?.questionsCompleted ?? 0,
                    correct: todayStats?.correctAnswers ?? 0,
                    incorrect: (todayStats?.questionsCompleted ?? 0) - (todayStats?.correctAnswers ?? 0),
                    size: circleSize
                )
                
                if selectedTimeRange == .month {
                    CircleProgressView(
                        progress: monthlyStats.total > 0 ? Double(monthlyStats.correct) / Double(monthlyStats.total) : 0,
                        title: "Monthly Accuracy",
                        total: monthlyStats.total,
                        correct: monthlyStats.correct,
                        incorrect: monthlyStats.incorrect,
                        size: circleSize
                    )
                } else {
                    CircleProgressView(
                        progress: calculateWeeklyProgress(),
                        title: "Weekly Accuracy",
                        total: calculateWeeklyTotal(),
                        correct: calculateWeeklyCorrect(),
                        incorrect: calculateWeeklyIncorrect(),
                        size: circleSize
                    )
                }
            }
            .padding(.top, 10)  // 상단 패딩 감소
        }
    }
    
    private func calculateWeeklyProgress() -> Double {
        let total = weeklyStats.reduce(0) { $0 + $1.questionsCompleted }
        let correct = weeklyStats.reduce(0) { $0 + $1.correctAnswers }
        return total > 0 ? Double(correct) / Double(total) : 0
    }
    
    private func calculateWeeklyTotal() -> Int {
        weeklyStats.reduce(0) { $0 + $1.questionsCompleted }
    }
    
    private func calculateWeeklyCorrect() -> Int {
        weeklyStats.reduce(0) { $0 + $1.correctAnswers }
    }
    
    private func calculateWeeklyIncorrect() -> Int {
        let total = calculateWeeklyTotal()
        let correct = calculateWeeklyCorrect()
        return total - correct
    }
}

struct CircleProgressView: View {
    let progress: Double
    let title: String
    let total: Int
    let correct: Int
    let incorrect: Int
    let size: CGFloat
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    
    private var titleFontSize: CGFloat {
        horizontalSizeClass == .regular ? size * 0.08 : size * 0.1
    }
    
    private var percentageFontSize: CGFloat {
        horizontalSizeClass == .regular ? size * 0.15 : size * 0.2
    }
    
    private var statsFontSize: CGFloat {
        horizontalSizeClass == .regular ? size * 0.08 : size * 0.1
    }
    
    private var statsSpacing: CGFloat {
        horizontalSizeClass == .regular ? 24 : 16
    }
    
    
    
    private var circleSize: CGFloat {
        // iPad에서는 더 큰 원형 프로그레스
        horizontalSizeClass == .regular ? 200 : 150
    }
    
    private var fontScale: CGFloat {
        // iPad에서는 더 큰 폰트 사이즈
        horizontalSizeClass == .regular ? 1.2 : 1.0
    }
    
    
    var body: some View {
        VStack(spacing: statsSpacing) {
            // 원형 프로그레스
            ZStack {
                Circle()
                    .stroke(lineWidth: size * 0.1)
                    .opacity(0.3)
                    .foregroundColor(.blue)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                    .foregroundColor(.green)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: progress)
                
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: percentageFontSize, weight: .bold))
                    Text(title)
                        .font(.system(size: titleFontSize))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: size, height: size)
            
            // 통계 정보
            VStack(alignment: .leading, spacing: 8) {
                statRow("Correct:", value: correct, color: .green)
                statRow("Incorrect:", value: incorrect, color: .red)
                statRow("Total:", value: total, color: .primary)
            }
            .font(.system(size: statsFontSize))
            .padding(.top, horizontalSizeClass == .regular ? 20 : 12)  // 상단 여백 추가
        }
        .padding()
    }
    
    private func statRow(_ title: String, value: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Text("\(value)")
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
    }
    
    private func statsLabel(_ title: String, value: Int, color: Color) -> some View {
        HStack {
            Text("\(title):")
            Text("\(value)")
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
    }
    
    private func statRow(title: String, value: Int, color: Color) -> some View {
        HStack {
            Text("\(title):")
                .font(.system(size: size * 0.12))
            Text("\(value)")
                .font(.system(size: size * 0.12, weight: .semibold))
                .foregroundColor(color)
        }
    }
}


struct ActivityRow: View {
   let title: String
   let value: String
   let icon: String
   let color: Color
   
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            
            Spacer()
        }
    }
}

struct DailyStatCard: View {
    let title: String
    let value: String
    let trend: String
    let trendUp: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .bold()
            
            if !trend.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                    Text(trend)
                }
                .font(.caption)
                .foregroundColor(trendUp ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
struct DayCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let date: Date
    let progress: DailyProgress
    let size: CGFloat
    let fontSize: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(getBackgroundColor())
                .frame(width: size, height: size)
            
            VStack(spacing: size * 0.1) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(getTextColor())
                if progress.questionsCompleted > 0 {
                    Text("\(progress.questionsCompleted)")
                        .font(.system(size: fontSize * 0.8))
                        .foregroundColor(getTextColor())
                }
            }
        }
    }
    
    private func getBackgroundColor() -> Color {
        if progress.questionsCompleted > 0 {
            return Color.green
        }
        return colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6)
    }
    
    private func getTextColor() -> Color {
        progress.questionsCompleted > 0 ? .white : (colorScheme == .dark ? .white : .primary)
    }
}

extension Calendar {
    func generateDates(
        for dateInterval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.reserveCapacity(40)

        var date = dateInterval.start
        repeat {
            dates.append(date)
            guard let nextDate = self.nextDate(after: date, matching: components, matchingPolicy: .nextTime) else {
                break
            }
            date = nextDate
        } while date <= dateInterval.end

        return dates
    }
}
