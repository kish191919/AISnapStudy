import SwiftUI
import Charts
import CoreData // Core Data 모듈을 import

struct StatView: View {
    @Environment(\.managedObjectContext) private var context // Core Data context
    @StateObject private var viewModel: StatViewModel
    let correctAnswers: Int
    let totalQuestions: Int
    
    init(correctAnswers: Int, totalQuestions: Int, context: NSManagedObjectContext) {
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        _viewModel = StateObject(wrappedValue: StatViewModel(context: context))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("학습 통계")
                    .font(.title)
                    .padding(.top)
                
                // 현재 스트릭
                HStack {
                    VStack(alignment: .leading) {
                        Text("현재 스트릭")
                            .font(.headline)
                        Text("\(viewModel.streak)일")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // 통계 그리드
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    StatCard(title: "총 점수",
                             value: "\(viewModel.totalPoints)점",
                             icon: "star.fill",
                             color: .yellow)
                    
                    StatCard(title: "완료한 문제",
                             value: "\(viewModel.completedQuestions)개",
                             icon: "checkmark.circle.fill",
                             color: .green)
                    
                    StatCard(title: "정답률",
                             value: String(format: "%.1f%%", viewModel.accuracyRate),
                             icon: "percent",
                             color: .blue)
                    
                    StatCard(title: "정답 수",
                             value: "\(viewModel.correctAnswers)개",
                             icon: "target",
                             color: .red)
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            viewModel.loadStats()
        }
    }
}
