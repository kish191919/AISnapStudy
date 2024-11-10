
import SwiftUI

struct ProgressRow: View {
    let subject: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(subject)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f%%", progress))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(getColor(for: subject))
                        .frame(width: geometry.size.width * min(max(progress / 100, 0), 1), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    private func getColor(for subject: String) -> Color {
        switch subject.lowercased() {
        case "language arts":
            return .blue
        case "math":
            return .green
        default:
            return .accentColor
        }
    }
}
