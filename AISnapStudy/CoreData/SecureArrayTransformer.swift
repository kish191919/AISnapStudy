// File: CoreData/SecureArrayTransformer.swift

import Foundation

@objc(SecureArrayTransformer)
final class SecureArrayTransformer: NSSecureUnarchiveFromDataTransformer {
    
    static let transformerName = NSValueTransformerName(rawValue: "SecureArrayTransformer")
    
    override static var allowedTopLevelClasses: [AnyClass] {
        [NSArray.self, NSString.self, NSDictionary.self]
    }
    
    static func register() {
        let transformer = SecureArrayTransformer()
        ValueTransformer.setValueTransformer(
            transformer,
            forName: transformerName
        )
    }
}
