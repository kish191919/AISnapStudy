// Utils/Helpers/ConfigurationManager.swift
import Foundation

enum ConfigurationError: Error {
    case missingKey(String)
    case invalidPlistFile
}

class ConfigurationManager {
    static let shared = ConfigurationManager()
    private var configurations: [String: Any]?
    
    private init() {
        loadConfigurations()
    }
    
    private func loadConfigurations() {
        guard let plistPath = Bundle.main.path(forResource: "Configuration", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return
        }
        
        configurations = plist
    }
    
    func getValue(for key: String) throws -> String {
        guard let configurations = configurations else {
            throw ConfigurationError.invalidPlistFile
        }
        
        guard let value = configurations[key] as? String else {
            throw ConfigurationError.missingKey(key)
        }
        
        return value
    }
}
