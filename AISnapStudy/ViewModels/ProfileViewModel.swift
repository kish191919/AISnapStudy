// ViewModels/ProfileViewModel.swift

import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    init() {
        // 실제 앱에서는 사용자 데이터를 로드하는 로직 구현
        self.user = User(
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
        
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    func showTerms() {
        guard let url = URL(string: "https://example.com/terms") else { return }
        UIApplication.shared.open(url)
    }
    
    func showPrivacyPolicy() {
        guard let url = URL(string: "https://example.com/privacy") else { return }
        UIApplication.shared.open(url)
    }
    
    func signOut() {
        // 로그아웃 로직 구현
    }
}
