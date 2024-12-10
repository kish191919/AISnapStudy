import SwiftUI

struct ReviewProblemSetCard: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject private var subjectManager = SubjectManager.shared
    
    let subject: SubjectType
    let problemSet: ProblemSet
    let isEditMode: Bool
    let onDelete: () -> Void
    let onRename: (String) -> Void
    let onFavoriteToggle: () -> Void
    
    @State private var isShowingRenameAlert = false
    @State private var isShowingSubjectPicker = false
    @State private var newName = ""
    @State private var isShowingMergeAlert = false
    @State private var isTargeted = false
    @State private var mergingProblemSets: (source: ProblemSet, target: ProblemSet)?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(problemSet.name.isEmpty ? "No Name" : problemSet.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await homeViewModel.toggleFavorite(problemSet)
                        }
                    }) {
                        Image(systemName: problemSet.isFavorite ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .imageScale(.large)
                    }
                }
                HStack {
                    Text("\(problemSet.questions.count) EA")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Created on: \(problemSet.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isEditMode {
                HStack(spacing: 12) {
                    Button(action: {
                        isShowingSubjectPicker = true
                    }) {
                        Image(systemName: "arrow.triangle.swap")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    
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
                .background(isTargeted ? Color.blue.opacity(0.1) : Color.clear)
        )
        .sheet(isPresented: $isShowingSubjectPicker) {
            SubjectPickerView(
                problemSet: problemSet,
                currentSubject: subject
            )
        }
        .alert("Rename Problem Set", isPresented: $isShowingRenameAlert) {
            TextField("New name", text: $newName)
            Button("Cancel", role: .cancel) {
                newName = ""
            }
            Button("Save") {
                let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else { return }
                
                Task {
                    await homeViewModel.renameProblemSet(problemSet, newName: trimmedName)
                    onRename(trimmedName)
                }
                newName = ""
            }
        } message: {
            Text("Enter a new name for this problem set")
        }
        // 드래그 앤 드롭 기능
        .draggable(problemSet) {
            DragPreviewView(problemSet: problemSet)
        }
        .dropDestination(for: ProblemSet.self) { droppedItems, location in
            guard let droppedSet = droppedItems.first,
                  droppedSet.id != problemSet.id else { return false }
            
            mergingProblemSets = (droppedSet, problemSet)
            newName = "\(droppedSet.name) + \(problemSet.name)"
            isShowingMergeAlert = true
            HapticManager.shared.impact(style: .medium)
            return true
        } isTargeted: { inDropArea in
            withAnimation(.easeInOut(duration: 0.2)) {
                isTargeted = inDropArea
            }
        }
        .alert("Create Combined Set", isPresented: $isShowingMergeAlert) {
            TextField("New set name", text: $newName)
            Button("Cancel", role: .cancel) {
                mergingProblemSets = nil
                newName = ""
            }
            Button("Create") {
                if let (source, target) = mergingProblemSets {
                    let mergedSet = ProblemSet.merge([source, target], name: newName)
                    Task {
                        // 새로운 병합된 세트만 저장하고 원본은 유지
                        await homeViewModel.saveProblemSet(mergedSet)
                        mergingProblemSets = nil
                        HapticManager.shared.notification(type: .success)  // 여기를 수정
                    }
                }
                newName = ""
            }
        } message: {
            if let sets = mergingProblemSets {
                Text("Create a new set by combining '\(sets.source.name)' with '\(sets.target.name)'\nOriginal sets will be preserved.")
            }
        }
    }
}

struct DragPreviewView: View {
    let problemSet: ProblemSet
    
    var body: some View {
        VStack(spacing: 4) {
            Text(problemSet.name)
                .font(.headline)
            Text("\(problemSet.questions.count) questions")
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 3)
    }
}
