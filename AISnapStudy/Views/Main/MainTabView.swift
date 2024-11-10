import SwiftUI

struct MainTabView: View {
    @StateObject private var homeViewModel = HomeViewModel() // HomeViewModel 인스턴스 생성
    @State private var selectedTab = 0
   
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: homeViewModel) // HomeView에 viewModel 전달
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
           
            if let problemSet = homeViewModel.selectedProblemSet {
                // StudyView를 호출하는 곳에서 정확한 변수 이름 사용
                StudyView(questions: problemSet.questions, homeViewModel: homeViewModel) // 여기에서 `homeViewModel` 사용

                    .tabItem { Label("Study", systemImage: "book.fill") }
                    .tag(1)
                    .id("\(problemSet.id)_\(problemSet.questions.count)")  // id 수정
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
        .onChange(of: homeViewModel.selectedProblemSet) { newValue in
            if selectedTab == 1 {
                // 강제로 탭을 변경했다가 다시 돌아와서 View 갱신
                selectedTab = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 1
                }
            }
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 1 {
                print("🔄 Study Tab selected - Refreshing view")
            }
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
            if let problemSet = homeViewModel.selectedProblemSet {
                withAnimation {
                    // 강제로 탭을 변경했다가 다시 돌아와서 View 갱신
                    selectedTab = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedTab = 1
                    }
                }
            }
        }
    }
}
