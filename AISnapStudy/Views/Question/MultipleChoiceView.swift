
import SwiftUI

struct MultipleChoiceView: View {
    let question: Question
    @Binding var selectedAnswer: String?
    let showExplanation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.question)
                .font(.headline)
                .padding(.bottom, 8)
            
            ForEach(question.options ?? [], id: \.self) { option in
                Button(action: { selectedAnswer = option }) {
                    HStack {
                        Text(option)
                            .foregroundColor(selectedAnswer == option ? .white : .primary)
                        Spacer()
                        if selectedAnswer == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedAnswer == option ? Color.accentColor : Color.secondaryBackground)
                    )
                }
                .disabled(showExplanation)
            }
        }.onAppear {
            print("\n🔤 Rendering MultipleChoiceView:")
            print("• Question: \(question.question)")
            print("• Options: \(question.options)")
        }
        .padding()
    }
}
