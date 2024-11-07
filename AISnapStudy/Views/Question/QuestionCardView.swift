// Views/Question/QuestionCardView.swift
// Views/Question/QuestionCardView.swift
import SwiftUI

struct QuestionCardView: View {
    let question: Question
    @Binding var selectedAnswer: String?
    @State private var showHint = false
    @State private var isSaved = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question Header
            HStack {
                Text(question.question)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { isSaved.toggle() }) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(.blue)
                }
            }
            
            // Hint Button
            Button(action: { showHint.toggle() }) {
                Label("Show Hint", systemImage: "lightbulb")
                    .foregroundColor(.gray)
            }
            
            if showHint {
                Text(question.hint ?? "")
                    .font(.subheadline)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Answer Options
            if !question.options.isEmpty { // if let 대신 빈 배열 체크
                ForEach(question.options, id: \.self) { option in
                    Button(action: { selectedAnswer = option }) {
                        HStack {
                            Text(option)
                            Spacer()
                            if selectedAnswer == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(
                            selectedAnswer == option ?
                                Color.blue.opacity(0.1) :
                                Color.gray.opacity(0.1)
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
