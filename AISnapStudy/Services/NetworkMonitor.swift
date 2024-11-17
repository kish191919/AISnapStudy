

import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    // MARK: - Singleton
    static let shared = NetworkMonitor()
    
    // MARK: - Properties
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor", qos: .utility)
    private var timestampQueue: TimestampQueue
    
    // MARK: - Published Properties
    @Published private(set) var status: NWPath.Status = .requiresConnection
    @Published private(set) var isReachable = false
    @Published private(set) var connectionType: NWInterface.InterfaceType?
    @Published private(set) var isExpensive = false
    @Published private(set) var isConstrained = false
    
    // MARK: - Constants
    private let maxTimestamps = 1000
    private let cleanupInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Debug Control
    private var shouldLog: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Initialization
    private init() {
        self.timestampQueue = TimestampQueue(maxSize: maxTimestamps)
        setupPeriodicCleanup()
        startMonitoring()
    }
    
    // MARK: - Monitoring
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.timestampQueue.enqueue(Date().timeIntervalSince1970)
            
            DispatchQueue.main.async {
                self.updateNetworkStatus(path)
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        self.status = path.status
        self.isReachable = path.status == .satisfied
        self.connectionType = path.availableInterfaces.first?.type
        self.isExpensive = path.isExpensive
        self.isConstrained = path.isConstrained
        
        if shouldLog {
            switch path.status {
            case .satisfied:
                // 중요한 네트워크 상태 변경만 노티피케이션 발송
                if !isReachable {
                    NotificationCenter.default.post(
                        name: Notification.Name("NetworkConnectionEstablished"),
                        object: nil
                    )
                }
            case .unsatisfied:
                Logger.log("Network disconnected", category: "Network")
            default:
                break
            }
        }
    }
    
    // MARK: - Network Status Check
    func checkNetworkAvailability() -> Bool {
        return status == .satisfied
    }
    
    func handleNetworkError(_ error: Error) async throws -> Bool {
        if !checkNetworkAvailability() {
            throw NetworkError.noConnection
        }
        return true
    }
    
    // MARK: - Timestamp Management
    private func setupPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            self?.performTimestampCleanup()
        }
    }
    
    private func performTimestampCleanup() {
        let currentTime = Date().timeIntervalSince1970
        timestampQueue.removeTimestampsBefore(currentTime - cleanupInterval)
        if shouldLog {
            Logger.log("Timestamp cleanup completed", category: "Network")
        }
    }
    
    // MARK: - Utility Methods
    func getInterfaceTypeString(_ type: NWInterface.InterfaceType?) -> String {
        guard let type = type else { return "unknown" }
        
        switch type {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Connection Management
    func getConnectionDetails() -> String {
        """
        Network Status:
        • Connection: \(isReachable ? "Connected" : "Disconnected")
        • Type: \(getInterfaceTypeString(connectionType))
        • Expensive: \(isExpensive ? "Yes" : "No")
        • Constrained: \(isConstrained ? "Yes" : "No")
        """
    }
    
    // MARK: - Cleanup
    func stopMonitoring() {
        monitor.cancel()
        if shouldLog {
            Logger.log("Network monitoring stopped", category: "Network")
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - TimestampQueue
private class TimestampQueue {
    private var timestamps: [TimeInterval]
    private let maxSize: Int
    
    init(maxSize: Int) {
        self.maxSize = maxSize
        self.timestamps = []
        timestamps.reserveCapacity(maxSize)
    }
    
    func enqueue(_ timestamp: TimeInterval) {
        if timestamps.count >= maxSize {
            timestamps.removeFirst()
        }
        timestamps.append(timestamp)
    }
    
    func removeTimestampsBefore(_ time: TimeInterval) {
        timestamps.removeAll { $0 < time }
    }
    
    var count: Int {
        timestamps.count
    }
}

// MARK: - Logger
private class Logger {
    static func log(_ message: String, category: String) {
        #if DEBUG
        print("📱 [\(category)] \(message)")
        #endif
    }
}
