import SwiftUI

struct SavedQuestionCard: View {
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(question.subject.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(question.subject.color.opacity(0.2))
                    .foregroundColor(question.subject.color)
                    .cornerRadius(8)
                
                Spacer()
            }
            
            // Question Type
            Text(question.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Question Text
            Text(question.question)
                .font(.subheadline)
                .lineLimit(2)
                .padding(.vertical, 4)
            
            // Footer
            HStack {
                Text("Saved \(question.createdAt.timeAgo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
        )
    }
}

#Preview {
    SavedQuestionCard(question: Question(
        id: UUID().uuidString,
        type: .multipleChoice,
        subject: .math,
        question: "Sample Question",
        options: ["A", "B", "C", "D"],
        correctAnswer: "A",
        explanation: "Sample explanation",
        hint: "Sample hint",
        isSaved: true,
        createdAt: Date()
    ))
    .padding()
}
