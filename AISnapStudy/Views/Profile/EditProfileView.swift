// Views/Profile/EditProfileView.swift

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditProfileViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $viewModel.name)
                        .textContentType(.name)
                    
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                }
                
                Section {
                    Button(action: viewModel.changePassword) {
                        Text("Change Password")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveChanges()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.hasChanges)
                }
            }
        }
    }
}

class EditProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    private var originalName: String = ""
    private var originalEmail: String = ""
    
    var hasChanges: Bool {
        name != originalName || email != originalEmail
    }
    
    init() {
        // 실제 앱에서는 현재 사용자 데이터를 로드
        let currentUser = User(
            id: "1",
            name: "Test User",
            email: "test@example.com",
            preferences: User.UserPreferences(
                isDarkMode: false,
                notificationsEnabled: true,
                dailyGoal: 5,
                preferredDifficulty: .medium
            ),
            createdAt: Date(),
            lastActive: Date()
        )
        
        self.name = currentUser.name
        self.email = currentUser.email
        self.originalName = currentUser.name
        self.originalEmail = currentUser.email
    }
    
    func changePassword() {
        // 비밀번호 변경 로직 구현
    }
    
    func saveChanges() async {
        // 프로필 변경 저장 로직 구현
    }
}
