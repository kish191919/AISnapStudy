import SwiftUI
import Charts
import CoreData

struct StatView: View {
    @ObservedObject var viewModel: StatViewModel // Change to ObservedObject
    @Binding var selectedTab: Int
    let correctAnswers: Int
    let totalQuestions: Int
    
 
    @EnvironmentObject private var homeViewModel: HomeViewModel

    
    init(correctAnswers: Int,
         totalQuestions: Int,
         viewModel: StatViewModel, // Pass viewModel directly
         selectedTab: Binding<Int>) {
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.viewModel = viewModel // Direct assignment without StateObject
        self._selectedTab = selectedTab
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
                        StatCard(title: "총 점수", value: "\(viewModel.totalPoints)점", icon: "star.fill", color: .yellow)
                        StatCard(title: "완료한 문제", value: "\(viewModel.completedQuestions)개", icon: "checkmark.circle.fill", color: .green)
                        StatCard(title: "정답률", value: String(format: "%.1f%%", viewModel.accuracyRate), icon: "percent", color: .blue)
                        StatCard(title: "정답 수", value: "\(viewModel.correctAnswers)개", icon: "target", color: .red)
                    }
                    .padding()
                    
                    // 다시 풀기 버튼
                    Button(action: {
                        // 먼저 상태 리셋
                        viewModel.resetProgress()
                        
                        // Study View로 전환하기 직전 상태 확인을 위해 viewModel에서 로그 출력
                        viewModel.logCurrentQuestionState()

                        // 바로 Study 탭으로 이동
                        withAnimation {
                            selectedTab = 1
                        }
                    }) {
                        Text("다시 풀기")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
    }
