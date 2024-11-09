// File: ./AISnapStudy/App/AISnapStudyApp.swift

import SwiftUI
import CoreData

@main
struct AISnapStudyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        validateCoreDataSetup()
        return true
    }
    
    private func validateCoreDataSetup() {
        let container = CoreDataService.shared.persistentContainer
        
        print("""
        📊 CoreData Configuration:
        • Store Descriptions: \(container.persistentStoreDescriptions.count)
        • View Context: \(container.viewContext)
        """)
        
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            print("• Store URL: \(storeURL)")
            
            let fileManager = FileManager.default
            if let parentDirectory = storeURL.deletingLastPathComponent().path as String? {
                if !fileManager.fileExists(atPath: parentDirectory) {
                    do {
                        try fileManager.createDirectory(
                            atPath: parentDirectory,
                            withIntermediateDirectories: true,
                            attributes: nil
                        )
                        print("✅ Created CoreData directory")
                    } catch {
                        print("❌ Failed to create CoreData directory: \(error)")
                    }
                }
            }
        }
    }
}
