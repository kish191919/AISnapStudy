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
            
            StudyView()
                .tabItem { Label("Study", systemImage: "book.fill") }
                .tag(1)
                .onChange(of: selectedTab) { newTab in
                    if newTab == 1 {
                        // 탭 전환 시 한 번만 실행되도록 수정
                        if homeViewModel.selectedProblemSet != nil {
                            print("📱 Study Tab Selected")
                        }
                    }
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
            withAnimation {
                selectedTab = 1  // Switch to Study tab
            }
        }
    }
}
