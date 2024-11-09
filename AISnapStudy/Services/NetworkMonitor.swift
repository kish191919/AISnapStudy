// Services/NetworkMonitor.swift

import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    @Published private(set) var status: NWPath.Status = .requiresConnection
    @Published private(set) var isReachable = false
    @Published private(set) var connectionType: NWInterface.InterfaceType?
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.status = path.status
                self?.isReachable = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                
                // 인터페이스 타입을 문자열로 변환하는 함수 사용
                let interfaceType = self?.getInterfaceTypeString(path.availableInterfaces.first?.type)
                
                print("""
                📡 Network Status Updated:
                • Is Reachable: \(path.status == .satisfied)
                • Interface Type: \(interfaceType ?? "unknown")
                • Is Expensive: \(path.isExpensive)
                • Is Constrained: \(path.isConstrained)
                """)
            }
        }
        
        monitor.start(queue: monitorQueue)
    }
    
    // 인터페이스 타입을 문자열로 변환하는 함수 추가
    private func getInterfaceTypeString(_ type: NWInterface.InterfaceType?) -> String {
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
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    deinit {
        stopMonitoring()
    }
}
