
import SwiftUI

struct ProblemSetCard: View {
    let problemSet: ProblemSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상단 헤더
            HStack {
                VStack(alignment: .leading) {
                    Text(problemSet.name)
                        .font(.headline)
                    Text(problemSet.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if problemSet.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            // 태그 목록
            if !problemSet.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(problemSet.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 정보 그리드
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                InfoRow(title: "Subject", value: problemSet.subject.displayName)
                InfoRow(title: "Level", value: problemSet.educationLevel.rawValue)
                InfoRow(title: "Questions", value: "\(problemSet.questions.count)")
                InfoRow(title: "Difficulty", value: problemSet.difficulty.rawValue)
            }
            .font(.caption)
            
            if let description = problemSet.problemSetDescription {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
