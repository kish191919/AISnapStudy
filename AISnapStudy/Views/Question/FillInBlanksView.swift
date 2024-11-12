
import SwiftUI

struct FillInBlanksView: View {
    let question: Question
    @Binding var answer: String?
    let showExplanation: Bool
    let isCorrect: Bool?  // 추가
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.question)
                .font(.headline)
            
            TextField("Your answer", text: Binding(
                get: { answer ?? "" },
                set: { answer = $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .disabled(showExplanation)
        }.onAppear {
            print("\n✏️ Rendering FillInBlanksView:")
            print("• Question: \(question.question)")
        }
        .padding()
    }
}
