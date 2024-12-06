
import SwiftUI

struct SubjectPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject private var subjectManager = SubjectManager.shared
    
    let problemSet: ProblemSet
    let currentSubject: SubjectType
    
    private func updateProblemSetSubject(to newSubject: SubjectType) async {
        await homeViewModel.updateProblemSetSubject(problemSet, to: newSubject)
        dismiss()
    }
    
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

}
