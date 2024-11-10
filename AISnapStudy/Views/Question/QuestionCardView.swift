
import SwiftUI

struct QuestionCardView: View {
    let question: Question
    @Binding var selectedAnswer: String?
    @Binding var isCorrect: Bool? // Bind to indicate if answer is correct
    var onAnswerSelected: (Bool) -> Void // Closure to handle answer selection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.question)
                .font(.title3)
                .fontWeight(.semibold)
            
            // Answer options
            ForEach(question.options, id: \.self) { option in
                Button(action: {
                    selectedAnswer = option
                    let correct = checkAnswer(option)
                    isCorrect = correct
                    onAnswerSelected(correct) // Pass result to parent view
                }) {
                    HStack {
                        Text(option)
                        Spacer()
                        if selectedAnswer == option {
                            Image(systemName: isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isCorrect == true ? .green : .red)
                        }
                    }
                    .padding()
                    .background(
                        selectedAnswer == option ?
                            (isCorrect == true ? Color.green.opacity(0.3) : Color.red.opacity(0.3)) :
                            Color.gray.opacity(0.1)
                    )
                    .cornerRadius(8)
                }
                .disabled(selectedAnswer != nil) // Disable buttons after selection
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Check if selected answer is correct
    private func checkAnswer(_ option: String) -> Bool {
        return option == question.correctAnswer
    }
}
