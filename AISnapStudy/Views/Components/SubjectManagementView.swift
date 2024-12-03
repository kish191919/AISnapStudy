import SwiftUI

struct SubjectManagementView: View {
   @StateObject private var subjectManager = SubjectManager.shared
   @State private var showingAddSubject = false
   @State private var showingDeleteAlert = false
   @State private var showingEditAlert = false
   @State private var showingRestoreAlert = false
   @State private var subjectToDelete: (any SubjectType)?
   @State private var newName = ""
   @State private var selectedSubject: (any SubjectType)?
   
   // 모든 활성 과목을 하나의 배열로 결합
   private var allSubjects: [SubjectType] {
       var subjects = DefaultSubject.allCases.filter { !subjectManager.isDeleted($0) } as [SubjectType]
       subjects.append(contentsOf: subjectManager.customSubjects)
       return subjects
   }
   
   var body: some View {
       List {
           // Combined Subjects Section
           Section(header: Text("SUBJECTS")) {
               ForEach(allSubjects, id: \.id) { subject in
                   if let defaultSubject = subject as? DefaultSubject {
                       DefaultSubjectRow(
                        subject: defaultSubject,
                        subjectManager: subjectManager,
                        onEdit: { subject in
                            selectedSubject = subject
                            newName = subjectManager.getDisplayName(for: subject)
                            showingEditAlert = true
                        },
                        onDelete: {
                            subjectToDelete = subject
                            showingDeleteAlert = true
                        }
                       )
                   } else if let customSubject = subject as? CustomSubject {
                       CustomSubjectRow(
                           subject: customSubject,
                           subjectManager: subjectManager,
                           onEdit: { subject in
                               selectedSubject = subject
                               newName = subject.name
                               showingEditAlert = true
                           },
                           onDelete: { subject in
                               subjectToDelete = subject
                               showingDeleteAlert = true
                           }
                       )
                   }
               }
               
               Button {
                   showingAddSubject = true
               } label: {
                   Label("Add Subject", systemImage: "plus")
               }
           }
           
           // Recently Deleted Section moved to bottom
           if !subjectManager.hiddenDefaultSubjects.isEmpty {
               Section(header: Text("RECENTLY DELETED")) {
                   Button(action: {
                       showingRestoreAlert = true
                   }) {
                       Label("Restore All Deleted Subjects", systemImage: "arrow.counterclockwise")
                           .foregroundColor(.blue)
                   }
               }
           }
       }
       .navigationTitle("Manage Subjects")
       .sheet(isPresented: $showingAddSubject) {
           AddSubjectView()
       }
       .alert("Rename Subject", isPresented: $showingEditAlert) {
           TextField("Subject Name", text: $newName)
           Button("Cancel", role: .cancel) { }
           Button("Save") {
               if let defaultSubject = selectedSubject as? DefaultSubject {
                   subjectManager.updateDefaultSubjectName(defaultSubject, newName: newName)
               } else if let customSubject = selectedSubject as? CustomSubject {  // 변경
                              subjectManager.updateSubject(customSubject, newName: newName)
               }
           }
           .disabled(newName.isEmpty)
       }
       .alert("Delete Subject", isPresented: $showingDeleteAlert) {
           Button("Cancel", role: .cancel) { }
           Button("Delete", role: .destructive) {
               if let subject = subjectToDelete as? DefaultSubject {
                   subjectManager.toggleDefaultSubject(subject)
               } else if let subject = subjectToDelete as? CustomSubject {  // 변경
                   subjectManager.deleteSubject(subject)
               }
           }
       } message: {
           Text("Are you sure you want to delete this subject? You can restore it later from the Recently Deleted section.")
       }
       .alert("Restore Subjects", isPresented: $showingRestoreAlert) {
           Button("Cancel", role: .cancel) { }
           Button("Restore All") {
               DefaultSubject.allCases.forEach { subject in
                   if subjectManager.isDeleted(subject) {
                       subjectManager.restoreDeletedSubject(subject)
                   }
               }
           }
       } message: {
           Text("Do you want to restore all deleted subjects?")
       }
       .onAppear {
           print("📱 SubjectManagementView appeared")
           print("📚 Active subjects: \(allSubjects.map { $0.displayName })")
           print("🗑️ Hidden subjects: \(subjectManager.hiddenDefaultSubjects)")
       }
   }
}

    
// 복원 섹션을 위한 별도의 뷰
struct RestoreSection: View {
    @ObservedObject var subjectManager: SubjectManager
    @Binding var showingRestoreAlert: Bool
    
    var body: some View {
        if !subjectManager.hiddenDefaultSubjects.isEmpty {
            Section(header: Text("Recently Deleted Subjects")) {
                Button(action: {
                    showingRestoreAlert = true
                }) {
                    Label("Restore All Deleted Subjects", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

    // 기본 과목 섹션을 위한 별도의 뷰
struct DefaultSubjectsSection: View {
    @ObservedObject var subjectManager: SubjectManager
    let onEdit: (DefaultSubject) -> Void
    let onDelete: (DefaultSubject) -> Void
    
    var body: some View {
        Section(header: Text("Default Subjects")) {
            ForEach(DefaultSubject.allCases.filter { !subjectManager.isDeleted($0) }, id: \.id) { subject in
                DefaultSubjectRow(
                    subject: subject,
                    subjectManager: subjectManager,
                    onEdit: { _ in onEdit(subject) },  // 수정된 부분
                    onDelete: { onDelete(subject) }     // 수정된 부분
                )
            }
        }
    }
}

// 커스텀 과목 섹션을 위한 별도의 뷰
struct CustomSubjectsSection: View {
    @ObservedObject var subjectManager: SubjectManager
    @Binding var showingAddSubject: Bool
    let onEdit: (CustomSubject) -> Void  // 변경
    let onDelete: (CustomSubject) -> Void  // 변경
    
    var body: some View {
        Section(header: Text("Custom Subjects")) {
            ForEach(subjectManager.customSubjects) { subject in
                CustomSubjectRow(
                    subject: subject,
                    subjectManager: subjectManager,
                    onEdit: { customSubject in  // 매개변수 이름 변경
                        onEdit(customSubject)
                    },
                    onDelete: { customSubject in  // 매개변수 이름 변경
                        onDelete(customSubject)
                    }
                )
            }
            
            Button {
                showingAddSubject = true
            } label: {
                Label("Add Subject", systemImage: "plus")
            }
        }
    }
}

struct DefaultSubjectRow: View {
    let subject: DefaultSubject
    @ObservedObject var subjectManager: SubjectManager
    let onEdit: (DefaultSubject) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: subject.icon)
                .foregroundColor(subject.color)
            Text(subjectManager.getDisplayName(for: subject))
            Spacer()
            
            Button(action: {
                onDelete()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit(subject)
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            if subjectManager.modifiedDefaultSubjects[subject.id] != nil {
                Button {
                    subjectManager.resetDefaultSubjectName(subject)
                } label: {
                    Label("Reset Name", systemImage: "arrow.counterclockwise")
                }
            }
        }
    }
}

// 사용자 정의 과목 행을 위한 컴포넌트
struct CustomSubjectRow: View {
    let subject: CustomSubject  // 변경
    @ObservedObject var subjectManager: SubjectManager
    let onEdit: (CustomSubject) -> Void  // 변경
    let onDelete: (CustomSubject) -> Void  // 변경
    
    var body: some View {
        HStack {
            Image(systemName: subject.icon)
                .foregroundColor(subject.color)
            Text(subject.displayName)
            Spacer()
            
            // 삭제 버튼 추가
            Button(action: {
                onDelete(subject)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            
            if !subject.isActive {
                Image(systemName: "eye.slash")
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit(subject)
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button {
                subjectManager.toggleSubjectActive(subject)
            } label: {
                if subject.isActive {
                    Label("Hide", systemImage: "eye.slash")
                } else {
                    Label("Show", systemImage: "eye")
                }
            }
            
            Button(role: .destructive) {
                onDelete(subject)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}



struct AddSubjectView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subjectManager = SubjectManager.shared
    @State private var subjectName = ""
    @State private var selectedColor = Color.blue
    @State private var selectedIcon = "book.fill"
    
    let availableIcons = [
        "book.fill", "pencil", "function", "globe",
        "atom", "flask.fill", "keyboard", "music.note"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subject Details")) {
                    TextField("Subject Name", text: $subjectName)
                    
                    ColorPicker("Choose Color", selection: $selectedColor)
                    
                    Picker("Choose Icon", selection: $selectedIcon) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Label(icon, systemImage: icon)
                                .tag(icon)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Add Subject")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        subjectManager.addSubject(
                            name: subjectName,
                            icon: selectedIcon
                        )
                        dismiss()
                    }
                    .disabled(subjectName.isEmpty)
                }
            }
        }
    }
}

