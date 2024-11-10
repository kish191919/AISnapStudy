// Views/Main/StatView.swift
import SwiftUI
import Charts

struct StatView: View {
    @StateObject private var viewModel = StatViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Progress Card
                    StatCard(title: "Overall Progress") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Total Questions")
                                Spacer()
                                Text("\(viewModel.totalQuestions)")
                                    .bold()
                            }
                            HStack {
                                Text("Average Score")
                                Spacer()
                                Text(viewModel.formatProgress(viewModel.averageScore))
                                    .bold()
                            }
                        }
                    }
                    
                    // Weekly Progress Chart
                    StatCard(title: "Weekly Progress") {
                        Chart(viewModel.weeklyProgress) { progress in
                            BarMark(
                                x: .value("Day", progress.day),
                                y: .value("Questions", progress.questionsCompleted)
                            )
                        }
                        .frame(height: 200)
                    }
                    
                    // Subject Performance
                    StatCard(title: "Subject Performance") {
                        VStack(spacing: 16) {
                            ProgressRow(
                                subject: "Language Arts",
                                progress: viewModel.languageArtsProgress
                            )
                            ProgressRow(
                                subject: "Math",
                                progress: viewModel.mathProgress
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .refreshable {
                viewModel.loadStats()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}
