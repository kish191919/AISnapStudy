import SwiftUI
import Charts

struct DailyStatsView: View {
   @ObservedObject var viewModel: StatViewModel
   @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
   


   
   // Stats 카드를 별도 View로 분리
   private var statsCards: some View {
       LazyVGrid(columns: [
           GridItem(.flexible()),
           GridItem(.flexible())
       ], spacing: 16) {
           DailyStatCard(
               title: "Today's Questions",
               value: "\(todayStats?.questionsCompleted ?? 0)",
               trend: "",
               trendUp: true
           )
           
           DailyStatCard(
               title: "Accuracy",
               value: String(format: "%.1f%%", todayStats?.accuracy ?? 0),
               trend: "",
               trendUp: true
           )
       }
   }
   
   // Activity Summary를 별도 View로 분리
   private var activitySummary: some View {
       VStack(alignment: .leading, spacing: 12) {
           Text("Activity Summary")
               .font(.headline)
           
           VStack(spacing: 16) {
               ActivityRow(title: "Most Active Day", value: "Wednesday", icon: "calendar", color: .blue)
               ActivityRow(title: "Best Subject", value: "Mathematics", icon: "function", color: .green)
               ActivityRow(title: "Study Streak", value: "\(viewModel.streak) days", icon: "flame.fill", color: .orange)
           }
       }
   }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                timePicker
                weeklyProgressChart
                statsCards.padding()
                activitySummary
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
            }
            .padding()
        }
        .navigationTitle("Daily Statistics")
    }
    
    private var weeklyProgressChart: some View {
           VStack(alignment: .leading, spacing: 16) {
               Text("Weekly Progress")
                   .font(.headline)
               
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
       }

   private var timePicker: some View {
       Picker("Time Range", selection: $selectedTimeRange) {
           ForEach(TimeRange.allCases, id: \.self) { range in
               Text(range.rawValue).tag(range)
           }
       }
       .pickerStyle(.segmented)
       .padding()
       .onChange(of: selectedTimeRange) { newRange in
           let period: StatsPeriod = switch newRange {
               case .week: .day
               case .month: .month
               case .year: .year
           }
           Task {
               await viewModel.loadStatsByPeriod(period)
           }
       }
   }
    


   
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
   
   private var todayStats: DailyProgress? {
       let calendar = Calendar.current
       let today = Date()
       
       let stats = viewModel.weeklyProgress
           .first { calendar.isDate($0.date, inSameDayAs: today) }
       
       if let stats = stats {
           print("Found today's stats: Questions=\(stats.questionsCompleted)")
       } else {
           print("No stats found for today")
       }
       
       return stats
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


