import SwiftUI
import CoreData

@main
struct AISnapStudyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        SecureArrayTransformer.register()
        setupAppearance()
        setupMetal()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
    }
    
    private func setupMetal() {
        // Metal 디바이스 체크
        guard MTLCreateSystemDefaultDevice() != nil else {
            print("Metal is not supported on this device")
            return
        }
        
        // MetalTools 프레임워크 초기화 지연
        DispatchQueue.main.async {
            // MetalTools 관련 작업
        }
    }
    
    private func setupAppearance() {
        // 네비게이션 바 스타일 설정
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // 탭 바 스타일 설정
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setupCoreData()
        
        // OpenAI API Key 초기 설정
        Task {
            do {
                try await OpenAIService.shared.fetchAPIKey()
                print("✅ Successfully initialized OpenAI API Key")
            } catch {
                print("❌ Failed to fetch OpenAI API Key: \(error)")
            }
        }
        
        return true
    }
    
    // 앱 종료 시 API Key 정리
    func applicationWillTerminate(_ application: UIApplication) {
        OpenAIService.shared.cleanup()
    }
    
    private func setupCoreData() {
        let container = CoreDataService.shared.persistentContainer
        
        print("""
        📊 CoreData Configuration:
        • Store Descriptions: \(container.persistentStoreDescriptions.count)
        • View Context: \(container.viewContext)
        """)
        
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            print("❌ No store URL found")
            return
        }
        
        print("• Store URL: \(storeURL)")
        createCoreDataDirectoryIfNeeded(at: storeURL)
        setupCoreDataOptions(container: container)
    }
    
    private func createCoreDataDirectoryIfNeeded(at storeURL: URL) {
        let fileManager = FileManager.default
        let parentDirectory = storeURL.deletingLastPathComponent().path
        
        guard !fileManager.fileExists(atPath: parentDirectory) else { return }
        
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
    
    private func setupCoreDataOptions(container: NSPersistentContainer) {
        // CoreData 옵션 설정
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 성능 최적화 설정
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.viewContext.name = "MainContext"
    }
    
    // MARK: - Memory Management
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        CoreDataService.shared.viewContext.refreshAllObjects()
    }
}
