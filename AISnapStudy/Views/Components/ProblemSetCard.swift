
import SwiftUI

struct ProblemSetCard: View {
    let problemSet: ProblemSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(problemSet.title)
                        .font(.headline)
                    
                    Text("\(problemSet.questionCount) questions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(problemSet.subject.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(problemSet.subject.color.opacity(0.2))
                    .foregroundColor(problemSet.subject.color)
                    .cornerRadius(4)
            }
            
            if let lastAttempted = problemSet.lastAttempted {
                Text("Last attempted \(lastAttempted.timeAgo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 난이도 표시
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { level in
                    Circle()
                        .fill(level <= problemSet.difficulty.level ?
                              problemSet.difficulty.color :
                              Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                
                Text(problemSet.difficulty.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
