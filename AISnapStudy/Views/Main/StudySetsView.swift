import SwiftUI

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
