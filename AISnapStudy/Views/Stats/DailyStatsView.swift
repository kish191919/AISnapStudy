import SwiftUI
import Charts

struct DailyStatsView: View {
    @ObservedObject var viewModel: StatViewModel
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var dailyProgressBinding: Binding<[DailyProgress]> {
        Binding(
            get: { viewModel.weeklyProgress },
            set: { viewModel.weeklyProgress = $0 }
        )
    }
    
    // weeklyProgress에서 오늘의 데이터만 정확하게 가져오기
    private var todayStats: DailyProgress? {
        let calendar = Calendar.current
        let today = Date()
        
        // 디버그: 현재 weeklyProgress 상태 출력
        print("DailyStatsView: Getting today's stats")
        viewModel.weeklyProgress.forEach { progress in
            print("Date: \(progress.date), Questions: \(progress.questionsCompleted)")
        }
        
        let stats = viewModel.weeklyProgress
            .first { calendar.isDate($0.date, inSameDayAs: today) }
        
        if let stats = stats {
            print("Found today's stats: Questions=\(stats.questionsCompleted)")
        } else {
            print("No stats found for today")
        }
        
        return stats
    }
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Daily Progress
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Progress")
                        .font(.headline)
                    
                    Chart {
                        ForEach(viewModel.weeklyProgress) { progress in
                            BarMark(
                                x: .value("Date", progress.date, unit: .day),
                                y: .value("Questions", progress.questionsCompleted)
                            )
                            .position(by: .value("Type", "Total"))
                            .foregroundStyle(.blue.opacity(0.3))
                            
                            BarMark(
                                x: .value("Date", progress.date, unit: .day),
                                y: .value("Questions", progress.correctAnswers)
                            )
                            .position(by: .value("Type", "Correct"))
                            .foregroundStyle(.green)
                        }
                    }
                    .onChange(of: viewModel.completedQuestions) { _ in
                        viewModel.updateStats(correctAnswers: viewModel.correctAnswers,
                                            totalQuestions: viewModel.completedQuestions)
                    }
                    .frame(height: 200)
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
                
                // Daily Stats Summary
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    DailyStatCard(
                        title: "Today's Questions",
                        value: "\(todayStats?.questionsCompleted ?? 0)",  // 수정된 부분
                        trend: "",  // trend는 일단 빈 문자열로
                        trendUp: true
                    )
                    
                    DailyStatCard(
                        title: "Accuracy",
                        value: String(format: "%.1f%%", todayStats?.accuracy ?? 0),  // 수정된 부분
                        trend: "",
                        trendUp: true
                    )

                    
                }
                .padding()
                
                // Activity Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity Summary")
                        .font(.headline)
                    
                    VStack(spacing: 16) {
                        ActivityRow(
                            title: "Most Active Day",
                            value: "Wednesday",
                            icon: "calendar",
                            color: .blue
                        )
                        
                        ActivityRow(
                            title: "Best Subject",
                            value: "Mathematics",
                            icon: "function",
                            color: .green
                        )
                        
                        ActivityRow(
                            title: "Study Streak",
                            value: "\(viewModel.streak) days",
                            icon: "flame.fill",
                            color: .orange
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .padding()
        }
        .navigationTitle("Daily Statistics")
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

struct ActivityRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .bold()
        }
    }
}
