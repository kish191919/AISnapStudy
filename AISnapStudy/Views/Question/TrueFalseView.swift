import SwiftUI

struct TrueFalseView: View {
   let question: Question
   @Binding var selectedAnswer: String?
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
           
           VStack(alignment: .leading, spacing: 12) {
               TrueFalseButton(
                   title: "True",
                   isSelected: selectedAnswer?.lowercased() == "true",
                   disabled: showExplanation
               ) {
                   selectedAnswer = "true"
               }
               
               TrueFalseButton(
                   title: "False",
                   isSelected: selectedAnswer?.lowercased() == "false",
                   disabled: showExplanation
               ) {
                   selectedAnswer = "false"
               }
           }
           
           // Answer Result
           if showExplanation {
               HStack {
                   if let isCorrect = isCorrect {
                       HStack {
                           Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                               .foregroundColor(isCorrect ? .green : .red)
                           
                           Text(isCorrect ? "Correct!" : "Incorrect")
                               .foregroundColor(isCorrect ? .green : .red)
                               .fontWeight(.semibold)
                       }
                       .padding(.vertical, 4)
                       
                       Spacer()
                   }
               }
               
               // Show correct answer if wrong
               if let isCorrect = isCorrect, !isCorrect {
                   Text("Answer: \(question.correctAnswer)")
                       .font(.subheadline)
                       .foregroundColor(.blue)
                       .padding(.vertical, 4)
               }
           }
           
           // Explanation Section
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
       .onChange(of: question.id) { _ in
           isExplanationVisible = false
       }
   }
}

struct TrueFalseButton: View {
   let title: String
   let isSelected: Bool
   let disabled: Bool
   let action: () -> Void
   
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
            HapticManager.shared.impact(style: .light)
        }) {
            HStack {
                Text(title)
                    .font(.body)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.2), value: isSelected)
        }
        .disabled(disabled)
    }
}
