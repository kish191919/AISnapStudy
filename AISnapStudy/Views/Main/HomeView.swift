import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel // 외부에서 전달받은 viewModel 사용
    @State private var sheetState: SheetState = .hidden
    
    private enum SheetState: Equatable {
        case hidden
        case showing(Subject)
    }
    
    private var isShowingSheet: Binding<Bool> {
        Binding(
            get: {
                if case .hidden = sheetState {
                    return false
                }
                return true
            },
            set: { isShowing in
                if !isShowing {
                    sheetState = .hidden
                }
            }
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Create New Questions Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Create New Questions")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            SubjectButton(
                                title: "Language Arts",
                                icon: "book.fill",
                                color: .blue
                            ) {
                                sheetState = .showing(.languageArts)
                            }
                            
                            SubjectButton(
                                title: "Math",
                                icon: "function",
                                color: .green
                            ) {
                                sheetState = .showing(.math)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // StudyView로 이동 버튼 추가
                    if let selectedProblemSet = viewModel.selectedProblemSet {
                        NavigationLink(destination: StudyView(questions: selectedProblemSet.questions, homeViewModel: viewModel)) {
                            Text("Go to Study")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
        }
        .sheet(isPresented: isShowingSheet) {
            if case let .showing(subject) = sheetState {
                QuestionSettingsView(subject: subject, homeViewModel: viewModel)
                    .interactiveDismissDisabled()
            }
        }
    }
}

struct SubjectButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SubjectButtonView(
                title: title,
                icon: icon,
                color: color
            )
        }
    }
}

struct SubjectButtonView: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            Spacer()
            Image(systemName: "chevron.right")
        }
        .foregroundColor(color)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
