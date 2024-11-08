// App/AISnapStudyApp.swift
import SwiftUI

@main
struct AISnapStudyApp: App {
    init() {
        setupAppearance()
        
        // Initialize CoreData stack
        _ = CoreDataService.shared
        
        // Check API key
        do {
            _ = try ConfigurationManager.shared.getValue(for: "OpenAIAPIKey")
        } catch {
            fatalError("OpenAI API key is not properly configured: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
    
    private func setupAppearance() {
        // Configure global UI appearance
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
