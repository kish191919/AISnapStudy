// File: ./AISnapStudy/Views/Question/TrueFalseView.swift

import SwiftUI

struct TrueFalseView: View {
    let question: Question
    @Binding var selectedAnswer: String?
    let showExplanation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.question)
                .font(.headline)
                .padding(.bottom, 8)
            
            HStack(spacing: 20) {
                TrueFalseButton(
                    title: "True",
                    isSelected: selectedAnswer == "true",
                    disabled: showExplanation
                ) {
                    selectedAnswer = "true"
                }
                
                TrueFalseButton(
                    title: "False",
                    isSelected: selectedAnswer == "false",
                    disabled: showExplanation
                ) {
                    selectedAnswer = "false"
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
    }
}

struct TrueFalseButton: View {
    let title: String
    let isSelected: Bool
    let disabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? .blue : .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .disabled(disabled)
    }
}
