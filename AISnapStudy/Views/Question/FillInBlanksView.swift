import SwiftUI

struct FillInBlanksView: View {
    let question: Question
    @Binding var answer: String?
    let showExplanation: Bool
    let isCorrect: Bool?
    
    @State private var isExplanationVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question Text
            Text(question.question)
                .font(.system(size: 22, weight: .semibold))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            
            // Answer Input - 수정된 부분
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Answer")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: Binding(
                    get: { answer ?? "" },
                    set: { answer = $0 }
                ))
                .font(.system(size: 18))
                .frame(minHeight: 30)  // 최소 높이 설정
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .disabled(showExplanation)
            }

            
            // Answer Result (only show when submitted)
            if showExplanation {
                if let isCorrect = isCorrect {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                        
                        Text(isCorrect ? "Correct!" : "Incorrect")
                            .foregroundColor(isCorrect ? .green : .red)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                    
                    // Show correct answer if wrong
                    if !isCorrect {
                        Text("Answer: \(question.correctAnswer)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 4)
                    }
                }
            }
            
            // Explanation Section (only show when icon is clicked)
            if showExplanation && isExplanationVisible {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Explanation")
                        .font(.headline)
                    Text(question.explanation)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .animation(.spring(), value: showExplanation)
        .animation(.spring(), value: isExplanationVisible)
        // 상태가 리셋될 때 설명 숨기기
        .onChange(of: question.id) { _ in
            isExplanationVisible = false
        }
    }
}
