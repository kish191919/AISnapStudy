import SwiftUI

struct StreakBadgeView: View {
    let streakInfo: StreakInfo
    
    private var streakMessage: String {
        switch streakInfo.currentStreak {
        case 2: return "2 Days! Keep going! 🎯"
        case 3: return "3 Days! You're on fire! 🔥"
        case 4: return "4 Days! Fantastic! ⭐️"
        case 5: return "5 Days! Incredible! 🌟"
        case 6: return "6 Days! Amazing! 🏆"
        case 7...: return "7+ Days! Legendary! 👑"
        default: return "Start your streak today! 💫"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("\(streakInfo.currentStreak)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.orange)
            
            Text("Day Streak")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(streakMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            if streakInfo.longestStreak > streakInfo.currentStreak {
                Text("Longest streak: \(streakInfo.longestStreak) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
        )
    }
}
