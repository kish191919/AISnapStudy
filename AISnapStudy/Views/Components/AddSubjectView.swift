

import SwiftUI


// Helper Views
struct IconSelectionButton: View {
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .frame(width: 50, height: 50)
                .foregroundColor(isSelected ? .white : color)
                .background(
                    Circle()
                        .fill(isSelected ? color : Color.gray.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                )
        }
    }
}

struct ColorSelectionButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

