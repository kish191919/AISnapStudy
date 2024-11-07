// Models/User.swift
import Foundation

struct User: Codable, Identifiable {
    let id: String
    var name: String
    var email: String
    var preferences: UserPreferences
    var createdAt: Date
    var lastActive: Date
    
    struct UserPreferences: Codable {
        var isDarkMode: Bool
        var notificationsEnabled: Bool
        var dailyGoal: Int
        var preferredDifficulty: Difficulty
    }
}
