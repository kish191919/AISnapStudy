

import SwiftUI

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                        Color.accentColor :
                        Color.gray.opacity(0.1)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
