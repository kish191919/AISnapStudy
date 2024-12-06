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
                            // Total Questions Bar
                            BarMark(
                                x: .value("Date", progress.date, unit: .day),
                                y: .value("Questions", progress.questionsCompleted)
                            )
                            .position(by: .value("Type", "Total"))
                            .foregroundStyle(.blue.opacity(0.3))

                            // Correct Answers Bar
                            BarMark(
                                x: .value("Date", progress.date, unit: .day),
                                y: .value("Questions", progress.correctAnswers)
                            )
                            .position(by: .value("Type", "Correct"))
                            .foregroundStyle(.green)
                        }
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
                        value: "\(viewModel.completedQuestions)",
                        trend: "+5",
                        trendUp: true
                    )
                    
                    DailyStatCard(
                        title: "Accuracy",
                        value: String(format: "%.1f%%", viewModel.accuracyRate),
                        trend: "+2.3%",
                        trendUp: true
                    )
                    
                    DailyStatCard(
                        title: "Study Time",
                        value: "45min",
                        trend: "+10min",
                        trendUp: true
                    )
                    
                    DailyStatCard(
                        title: "Current Streak",
                        value: "\(viewModel.streak) days",
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
