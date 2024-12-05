
import SwiftUI

struct SubjectPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject private var subjectManager = SubjectManager.shared
    
    let problemSet: ProblemSet
    let currentSubject: SubjectType
    
    var body: some View {
        NavigationView {
            List {
                ForEach(subjectManager.availableSubjects, id: \.id) { subject in
                    Button(action: {
                        Task {
                            await updateProblemSetSubject(to: subject)
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: subject.icon)
                                .foregroundColor(subject.color)
                            
                            Text(subject.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if subject.id == currentSubject.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Change Subject")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func updateProblemSetSubject(to newSubject: SubjectType) async {
        let updatedProblemSet = ProblemSet(
            id: problemSet.id,
            subject: newSubject,
            subjectType: newSubject is DefaultSubject ? "default" : "custom",
            subjectId: newSubject.id,
            subjectName: newSubject.displayName,
            questions: problemSet.questions,
            createdAt: problemSet.createdAt,
            educationLevel: problemSet.educationLevel,
            name: problemSet.name  // 현재 이름 유지
        )
        
        await homeViewModel.saveProblemSet(updatedProblemSet)
    }

}
