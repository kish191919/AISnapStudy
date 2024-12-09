import SwiftUI
import Charts

struct DetailedStatsView: View {
    @StateObject private var viewModel = DetailedStatsViewModel()
    @State private var selectedMonth = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Streak Badge Section
                StreakBadgeView(streakInfo: viewModel.streakInfo)
                    .padding()
                
                // Calendar View
                CalendarStatsView(monthlyData: viewModel.monthlyData)
                .padding()
                
                // Stats Summary
                StatsSummaryView(dailyStats: viewModel.dailyStats)
                    .padding()
                
                // Progress Chart
                ProgressChartView(dailyStats: viewModel.dailyStats)
                    .frame(height: 250)
                    .padding()
            }
        }
        .navigationTitle("Detailed Stats")
    }
}

struct StatsSummaryView: View {
    let dailyStats: [DailyStats]
    
    private var totalQuestions: Int {
        dailyStats.reduce(0) { $0 + $1.totalQuestions }
    }
    
    private var totalCorrect: Int {
        dailyStats.reduce(0) { $0 + $1.correctAnswers }
    }
    
    private var averageAccuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalQuestions) * 100
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Total",
                    value: "\(totalQuestions)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatCard(
                    title: "Correct",
                    value: "\(totalCorrect)",
                    icon: "checkmark",
                    color: .green
                )
                
                StatCard(
                    title: "Accuracy",
                    value: String(format: "%.1f%%", averageAccuracy),
                    icon: "percent",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ProgressChartView: View {
    let dailyStats: [DailyStats]
    
    var body: some View {
        Chart {
            ForEach(dailyStats) { stats in
                BarMark(
                    x: .value("Date", stats.date),
                    y: .value("Questions", stats.totalQuestions)
                )
                .foregroundStyle(by: .value("Type", "Total"))
                
                BarMark(
                    x: .value("Date", stats.date),
                    y: .value("Questions", stats.correctAnswers)
                )
                .foregroundStyle(by: .value("Type", "Correct"))
            }
        }
        .chartForegroundStyleScale([
            "Total": Color.blue.opacity(0.3),
            "Correct": Color.green
        ])
        .chartLegend(position: .top)
    }
}
