import SwiftUI

struct DraggableSubjectGrid: View {
    @ObservedObject var subjectManager = SubjectManager.shared
    @State private var subjects: [SubjectType]
    @State private var draggingItem: SubjectType?
    @GestureState private var dragLocation: CGPoint = .zero
    
    // Grid layout settings
    let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]
    
    init(subjects: [SubjectType]) {
        _subjects = State(initialValue: subjects)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(subjects, id: \.id) { subject in
                SubjectButton(subject: subject)
                    .overlay(draggingItem?.id == subject.id ? Color.blue.opacity(0.3) : Color.clear)
                    .onLongPressGesture(minimumDuration: 0.5) {
                        withAnimation(.spring()) {
                            self.draggingItem = subject
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard let draggingItem = draggingItem else { return }
                                let currentIndex = subjects.firstIndex { $0.id == draggingItem.id }
                                let targetIndex = computeTargetIndex(location: value.location)
                                
                                if let currentIndex = currentIndex,
                                   let targetIndex = targetIndex,
                                   currentIndex != targetIndex {
                                    withAnimation(.spring()) {
                                        subjects.move(fromOffsets: IndexSet(integer: currentIndex),
                                                    toOffset: targetIndex)
                                    }
                                }
                            }
                            .onEnded { _ in
                                self.draggingItem = nil
                                // Save new order to UserDefaults
                                saveSubjectOrder()
                            }
                    )
            }
        }
        .padding()
    }
    
    private func computeTargetIndex(location: CGPoint) -> Int? {
        // Convert point to index logic
        // ...
        return nil
    }
    
    private func saveSubjectOrder() {
        let subjectIds = subjects.map { $0.id }
        UserDefaults.standard.set(subjectIds, forKey: "subjectOrder")
    }
}

struct SubjectButton: View {
    let subject: SubjectType
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: subject.icon)
                    .font(.system(size: 24))
                Text(subject.displayName)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(subject.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(subject.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isPressed ? 1.05 : 1.0)
        .animation(.spring(), value: isPressed)
        .buttonStyle(PlainButtonStyle())
    }
}
