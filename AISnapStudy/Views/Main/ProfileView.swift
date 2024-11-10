// Views/Main/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @State private var showingEditProfile = false
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading) {
                            Text(viewModel.user.name)
                                .font(.headline)
                            Text(viewModel.user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Settings Section
                Section("Settings") {
                    Toggle("Dark Mode", isOn: $viewModel.isDarkMode)
                    Toggle("Notifications", isOn: $viewModel.notificationsEnabled)
                    
                    NavigationLink("Study Preferences") {
                        StudyPreferencesView()
                    }
                }
                
                // App Info Section
                Section("App Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Terms of Service") {
                        viewModel.showTerms()
                    }
                    
                    Button("Privacy Policy") {
                        viewModel.showPrivacyPolicy()
                    }
                }
                
                // Account Actions
                Section {
                    Button("Sign Out", role: .destructive) {
                        viewModel.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
        }
    }
}
