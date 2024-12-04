import SwiftUI

struct ReviewProblemSetCard: View {
    let subject: SubjectType
    let problemSet: ProblemSet
    let isEditMode: Bool
    let onDelete: () -> Void
    let onRename: (String) -> Void
    
    @State private var isShowingRenameAlert = false
    @State private var newName = ""
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(problemSet.name.isEmpty ? "No Name" : problemSet.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if problemSet.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                }
                
                Text("Created on: \(problemSet.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 편집 모드일 때만 보이는 버튼들
            if isEditMode {
                HStack(spacing: 12) {
                    Button(action: {
                        newName = problemSet.name
                        isShowingRenameAlert = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .imageScale(.large)
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .alert("Rename Problem Set", isPresented: $isShowingRenameAlert) {
            TextField("New name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !newName.isEmpty {
                    onRename(newName)
                }
            }
        }
    }
}
