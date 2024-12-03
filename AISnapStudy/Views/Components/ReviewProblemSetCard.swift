import SwiftUI

struct ReviewProblemSetCard: View {
    let subject: SubjectType
    let problemSet: ProblemSet
    let onDelete: () -> Void
    let onRename: (String) -> Void
    
    @State private var isShowingRenameAlert = false
    @State private var newName = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(problemSet.name.isEmpty ? "No Name" : problemSet.name)
                    .font(.headline)
                    .foregroundColor(.primary)
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
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .padding(.vertical, 4)
        .contextMenu {
            // Rename option
            Button(action: {
                newName = problemSet.name
                isShowingRenameAlert = true
            }) {
                Label("Rename", systemImage: "pencil")
            }
            
            // Delete option
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Rename Problem Set", isPresented: $isShowingRenameAlert) {
            TextField("New name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !newName.isEmpty {
                    onRename(newName)
                }
            }
        } message: {
            Text("Enter a new name for this problem set")
        }
    }
}
