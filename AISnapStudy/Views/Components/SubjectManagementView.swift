

import SwiftUI

// 메인 SubjectManagementView
struct SubjectManagementView: View {
    @StateObject private var subjectManager = SubjectManager.shared
    @State private var showingAddSubject = false
    @State private var showingEditAlert = false
    @State private var showingDeleteAlert = false
    @State private var newName = ""
    @State private var selectedSubject: (any SubjectType)?
    @State private var subjectToDelete: SubjectManager.CustomSubject?
    
    var body: some View {
        List {
            Section(header: Text("Default Subjects")) {
                ForEach(DefaultSubject.allCases, id: \.id) { subject in
                    DefaultSubjectRow(
                        subject: subject,
                        subjectManager: subjectManager
                    ) { subject in
                        selectedSubject = subject
                        newName = subjectManager.getDisplayName(for: subject)
                        showingEditAlert = true
                    }
                }
            }
            
            Section(header: Text("Custom Subjects")) {
                ForEach(subjectManager.customSubjects) { subject in
                    CustomSubjectRow(
                        subject: subject,
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
                
                Button {
                    showingAddSubject = true
                } label: {
                    Label("Add Subject", systemImage: "plus")
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
                } else if let customSubject = selectedSubject as? SubjectManager.CustomSubject {
                    subjectManager.updateSubject(customSubject, newName: newName)
                }
            }
            .disabled(newName.isEmpty)
        }
        .alert("Delete Subject", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let subject = subjectToDelete {
                    subjectManager.deleteSubject(subject)
                }
            }
        } message: {
            Text("Are you sure you want to delete this subject? This action cannot be undone.")
        }
    }
}

struct DefaultSubjectRow: View {
    let subject: DefaultSubject
    let subjectManager: SubjectManager
    let onEdit: (DefaultSubject) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: subject.icon)
                .foregroundColor(subject.color)
            Text(subjectManager.getDisplayName(for: subject))
            Spacer()
            if subjectManager.hiddenDefaultSubjects.contains(subject.id) {
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
            
            if subjectManager.modifiedDefaultSubjects[subject.id] != nil {
                Button {
                    subjectManager.resetDefaultSubjectName(subject)
                } label: {
                    Label("Reset Name", systemImage: "arrow.counterclockwise")
                }
            }
            
            Button {
                subjectManager.toggleDefaultSubject(subject)
            } label: {
                if subjectManager.hiddenDefaultSubjects.contains(subject.id) {
                    Label("Show", systemImage: "eye")
                } else {
                    Label("Hide", systemImage: "eye.slash")
                }
            }
        }
    }
}
// 사용자 정의 과목 행을 위한 컴포넌트
struct CustomSubjectRow: View {
    let subject: SubjectManager.CustomSubject
    let subjectManager: SubjectManager
    let onEdit: (SubjectManager.CustomSubject) -> Void
    let onDelete: (SubjectManager.CustomSubject) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: subject.icon)
                .foregroundColor(subject.color)
            Text(subject.displayName)
            Spacer()
            if !subject.isActive {
                Image(systemName: "eye.slash")
                    .foregroundColor(.gray)
            }
        }
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
                            color: selectedColor,
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

