import SwiftUI

// StudySetsView 컴포넌트
struct StudySetsView: View {
    let viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(viewModel.remoteSets) { set in
                        DownloadableSetCard(
                            set: set,
                            action: {
                                Task {
                                    await viewModel.downloadQuestionSet(set)
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Study Sets")
                        .font(.system(size: 22, weight: .semibold)) // 크기와 굵기 조정
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


// LocalSetCard 컴포넌트
struct LocalSetCard: View {
    let set: ProblemSet
    let viewModel: HomeViewModel
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(set.name)
                            .font(.headline)
                        Text("\(set.questions.count) Questions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await viewModel.toggleFavorite(set)
                        }
                    } label: {
                        Image(systemName: set.isFavorite ? "star.fill" : "star")
                            .foregroundColor(set.isFavorite ? .yellow : .gray)
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}
