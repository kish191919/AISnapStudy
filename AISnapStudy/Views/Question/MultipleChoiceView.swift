
import SwiftUI

struct MultipleChoiceView: View {
    let question: Question
    @Binding var selectedAnswer: String?
    let showExplanation: Bool
    let isCorrect: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.question)
                .font(.headline)
                .padding(.bottom, 8)
            
            ForEach(question.options ?? [], id: \.self) { option in
                Button(action: { selectedAnswer = option }) {
                    HStack {
                        Text(option)
                            .foregroundColor(getTextColor(for: option))
                        Spacer()
                        if selectedAnswer == option && showExplanation {
                            Image(systemName: isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isCorrect == true ? .green : .red)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(getBackgroundColor(for: option))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(getBorderColor(for: option), lineWidth: 2)
                    )
                }
                .disabled(showExplanation)
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.3), value: selectedAnswer)
        .animation(.easeInOut(duration: 0.3), value: showExplanation)
        .animation(.easeInOut(duration: 0.3), value: isCorrect)
    }
    
    private func getBackgroundColor(for option: String) -> Color {
        if selectedAnswer == option {
            if !showExplanation {
                return Color.blue.opacity(0.1)  // 선택했을 때 파란색
            } else {
                return (isCorrect == true ? Color.green : Color.red).opacity(0.1)  // 제출 후
            }
        }
        return Color.gray.opacity(0.05)
    }
    
    private func getBorderColor(for option: String) -> Color {
        if selectedAnswer == option {
            if !showExplanation {
                return .blue  // 선택했을 때 파란색
            } else {
                return isCorrect == true ? .green : .red  // 제출 후
            }
        }
        return .clear
    }
    
    private func getTextColor(for option: String) -> Color {
        if selectedAnswer == option {
            if !showExplanation {
                return .blue  // 선택했을 때 파란색
            } else {
                return isCorrect == true ? .green : .red  // 제출 후
            }
        }
        return .primary
    }
}
