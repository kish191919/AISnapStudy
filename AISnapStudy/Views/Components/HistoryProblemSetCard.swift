import SwiftUI

struct HistoryProblemSetCard: View {
    let problemSet: ProblemSet
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(problemSet.name.isEmpty ? "No Name" : problemSet.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(problemSet.title.isEmpty ? "No Title" : problemSet.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Created on: \(problemSet.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if problemSet.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1))
        .padding(.vertical, 4)
    }
}
