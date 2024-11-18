import SwiftUI
import Charts
import CoreData


struct StatView: View {
    @ObservedObject var viewModel: StatViewModel
    @Binding var selectedTab: Int
    let correctAnswers: Int
    let totalQuestions: Int
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    // 초기화 함수의 매개변수 순서 수정
    init(
        viewModel: StatViewModel,
        selectedTab: Binding<Int>,
        correctAnswers: Int,
        totalQuestions: Int
    ) {
        self.viewModel = viewModel
        self._selectedTab = selectedTab
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
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
                    StatCard(
                        title: "이번 세트 점수",
                        value: "\(correctAnswers * 10)점",  // correctAnswers 직접 사용
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    StatCard(
                        title: "정답률",
                        value: String(format: "%.1f%%",
                            Double(correctAnswers) / Double(totalQuestions) * 100),
                        icon: "percent",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "완료한 문제",
                        value: "\(totalQuestions)개",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "정답 수",
                        value: "\(correctAnswers)개",
                        icon: "target",
                        color: .red
                    )
                }
                .padding()
                
                Spacer()  // 나머지 공간을 채움
                
                // 다시 풀기 버튼을 맨 아래에 배치
                Button(action: {
                    viewModel.resetProgress()
                    viewModel.logCurrentQuestionState()
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
                .padding(.horizontal)
                .padding(.bottom, 20)  // 하단 여백 추가
            }
        }
    }
}
