import SwiftUI
import Charts
import CoreData


struct StatView: View {
   @ObservedObject var viewModel: StatViewModel
   @Binding var selectedTab: Int
   let correctAnswers: Int
   let totalQuestions: Int
   @Environment(\.horizontalSizeClass) var horizontalSizeClass

   
   var incorrectAnswers: Int {
       totalQuestions - correctAnswers
   }
   
   var percentageCorrect: Int {
       guard totalQuestions > 0 else { return 0 }
       return Int((Double(correctAnswers) / Double(totalQuestions)) * 100)
   }
    
    // iPad에서의 최대 컨텐츠 너비
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 800 : .infinity
    }
    
    // 원형 프로그레스 크기 조정
    private var circleSize: CGFloat {
        horizontalSizeClass == .regular ? 250 : 200
    }
   
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Text("Result")
                        .font(.system(size: 34, weight: .bold))
                        .padding(.top)
                    
                    // Progress Circle
                    ZStack {
                        Circle()
                            .trim(from: 0, to: 1)
                            .stroke(Color.orange, lineWidth: horizontalSizeClass == .regular ? 30 : 25)
                            .rotationEffect(.degrees(-90))
                            .frame(width: circleSize, height: circleSize)
                        
                        Circle()
                            .trim(from: 0, to: Double(correctAnswers) / Double(totalQuestions))
                            .stroke(Color.green, lineWidth: horizontalSizeClass == .regular ? 30 : 25)
                            .rotationEffect(.degrees(-90))
                            .frame(width: circleSize, height: circleSize)
                        
                        Text("\(percentageCorrect)%")
                            .font(.system(size: horizontalSizeClass == .regular ? 50 : 40, weight: .bold))
                    }
                    .padding(.vertical)
                    
                    // Correct/Incorrect Labels
                    HStack(spacing: horizontalSizeClass == .regular ? 100 : 50) {
                        statsLabel(title: "Correct", count: correctAnswers, color: .green)
                        statsLabel(title: "Incorrect", count: incorrectAnswers, color: .orange)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        actionButton(title: "Retry Test", color: .blue) {
                            viewModel.resetProgress()
                            viewModel.logCurrentQuestionState()
                            withAnimation {
                                selectedTab = 1
                            }
                        }
                        
                        actionButton(title: "Take New Test", color: .green) {
                            withAnimation {
                                selectedTab = 2
                            }
                        }
                    }
                    .padding(.horizontal, geometry.size.width * 0.1)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
    }
    
    private func statsLabel(title: String, count: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .foregroundColor(color)
            Text("\(count)")
                .font(.headline)
                .padding(8)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
        }
        .font(.system(size: horizontalSizeClass == .regular ? 20 : 16))
    }
    
    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: horizontalSizeClass == .regular ? 20 : 16, weight: .semibold))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color)
                .cornerRadius(10)
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
    }
}
