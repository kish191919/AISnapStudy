
import SwiftUI

struct SavedProblemCard: View {
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(question.subject.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(question.subject.color.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
            }
            
            Text(question.question)
                .font(.subheadline)
                .lineLimit(2)
            
            HStack {
                Text("Saved \(question.createdAt.timeAgo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
