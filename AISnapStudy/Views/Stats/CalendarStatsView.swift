import SwiftUI

struct CalendarStatsView: View {
    @Binding var selectedMonth: Date
    let monthlyData: [Date: [DailyStats]]
    private let calendar = Calendar.current
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
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
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(days, id: \.self) { date in
                    if let stats = statsFor(date: date) {
                        DayCellView(stats: stats)
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
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

struct DayCellView: View {
    let stats: DailyStats
    
    private var accuracyColor: Color {
        let accuracy = stats.accuracy
        switch accuracy {
        case 90...100: return .green
        case 70..<90: return .blue
        case 50..<70: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(accuracyColor.opacity(0.2))
            
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: stats.date))")
                    .font(.caption2)
                Text("\(Int(stats.accuracy))%")
                    .font(.system(size: 8))
                    .foregroundColor(accuracyColor)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
