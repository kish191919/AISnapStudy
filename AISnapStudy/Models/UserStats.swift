import Foundation

struct StreakInfo: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let lastActiveDate: Date
}
