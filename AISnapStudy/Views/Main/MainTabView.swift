// Views/Main/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            
            // Observe selectedProblemSet changes to update StudyView with the latest problem set
            if let problemSet = homeViewModel.selectedProblemSet {
                StudyView(questions: problemSet.questions)
                    .tabItem { Label("Study", systemImage: "book.fill") }
                    .tag(1)
                    .onAppear {
                        if selectedTab == 1 {
                            // Refresh StudyView with new questions on selectedProblemSet update
                            selectedTab = 1
                        }
                    }
            } else {
                Text("No Problem Set Selected")
                    .tabItem { Label("Study", systemImage: "book.fill") }
                    .tag(1)
            }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .environmentObject(homeViewModel)
        .onAppear {
            setupNotifications()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowStudyView"),
            object: nil,
            queue: .main
        ) { _ in
            print("🔄 Switching to Study Tab")
            if homeViewModel.selectedProblemSet != nil {
                withAnimation {
                    selectedTab = 1  // Switch to Study tab after ProblemSet is loaded
                }
            }
        }
    }
}
