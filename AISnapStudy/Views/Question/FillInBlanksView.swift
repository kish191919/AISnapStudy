// Views/Question/FillInBlanksView.swift
import SwiftUI

struct FillInBlanksView: View {
    let question: Question
    @Binding var answer: String?
    let showExplanation: Bool
    
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
