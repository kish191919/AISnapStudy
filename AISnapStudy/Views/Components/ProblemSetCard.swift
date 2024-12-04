
import SwiftUI

struct ProblemSetCard: View {
    let problemSet: ProblemSet
    
    // Add selection state
    @Binding var isSelected: Bool
    let selectionEnabled: Bool // 새로운 프로퍼티 추가
    
    // 기본값을 가진 생성자 추가
    init(problemSet: ProblemSet, isSelected: Binding<Bool> = .constant(false), selectionEnabled: Bool = false) {
        self.problemSet = problemSet
        self._isSelected = isSelected
        self.selectionEnabled = selectionEnabled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if selectionEnabled {  // isSelectable 대신 selectionEnabled 사용
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            isSelected.toggle()
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(problemSet.name.isEmpty ? "No Name" : problemSet.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                Spacer()
                if problemSet.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            // 태그 목록 (작고 간결하게)
            if !problemSet.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(problemSet.tags.prefix(3), id: \.self) { tag in // 최대 3개의 태그만 표시
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    if problemSet.tags.count > 3 {
                        Text("+\(problemSet.tags.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            } else {
                Text("No Tags")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 정보 그리드
            HStack(spacing: 12) {
                InfoRow(title: "Subject", value: problemSet.subject.displayName)
                InfoRow(title: "Level", value: problemSet.educationLevel.rawValue)
                InfoRow(title: "Questions", value: "\(problemSet.questions.count)")
            }
            .font(.footnote)
            
            // 설명 (더 짧게)
            if let description = problemSet.problemSetDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.systemBackground)).shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2))
        .padding(.horizontal)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value.isEmpty ? "N/A" : value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

