
import SwiftUI

struct MultipleChoiceView: View {
    let question: Question
    @Binding var selectedAnswer: String?
    let showExplanation: Bool
    let isCorrect: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 질문 텍스트
            Text(question.question)
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
            
            // 선택지
            VStack(spacing: 16) {
                ForEach(question.options, id: \.self) { option in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAnswer = option
                        }
                        HapticManager.shared.impact(style: .light)
                    }) {
                        HStack {
                            Text(option)
                                .font(.body)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(getTextColor(for: option))
                            Spacer()
                            if selectedAnswer == option && showExplanation {
                                Image(systemName: isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isCorrect == true ? .green : .red)
                                    .imageScale(.large)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(getBackgroundColor(for: option))
                        )
                        .scaleEffect(selectedAnswer == option ? 1.02 : 1.0)
                        .animation(.spring(response: 0.2), value: selectedAnswer == option)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedAnswer == option ? Color.blue : Color.clear, lineWidth: 2)
                                .opacity(selectedAnswer == option ? 1 : 0)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(showExplanation)
                }
            }
        }
        .padding()
    }
    
    private func getBackgroundColor(for option: String) -> Color {
        if selectedAnswer == option {
            if !showExplanation {
                return Color.blue.opacity(0.15)
            } else {
                return (isCorrect == true ? Color.green : Color.red).opacity(0.15)
            }
        }
        // 기본 배경색을 조금 더 명확하게 구분
        return Color(UIColor.systemGray6)
    }
    
    private func getTextColor(for option: String) -> Color {
        if selectedAnswer == option {
            if !showExplanation {
                return .blue
            } else {
                return isCorrect == true ? .green : .red
            }
        }
        return .primary
    }
}
