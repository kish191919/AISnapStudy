
import SwiftUI

struct DifficultySelector: View {
    @Binding var selectedDifficulty: Difficulty
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                DifficultyButton(
                    difficulty: difficulty,
                    isSelected: selectedDifficulty == difficulty,
                    action: { selectedDifficulty = difficulty }
                )
            }
        }
        .padding(.horizontal)
    }
}

// 별도의 버튼 컴포넌트로 분리
private struct DifficultyButton: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: difficulty.iconName)
                    .font(.system(size: 24))
                Text(difficulty.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
        }
    }
    
    private var backgroundColor: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.accentColor : Color.secondaryBackground)
    }
    
    private var foregroundColor: Color {
        isSelected ? .white : .primary
    }
}

