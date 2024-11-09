// Utils/Helpers/ImageCompressor.swift
import UIKit

enum ImageCompressorError: Error {
    case compressionFailed
    case invalidImage
}

class ImageCompressor {
    static let shared = ImageCompressor()
    
    private enum Constraints {
        static let targetFileSize = 800 * 1024  // 800KB
        static let minDimension: CGFloat = 640
        static let maxDimension: CGFloat = 800
        static let minimumQuality: CGFloat = 0.5
    }
    
    private init() {}
    
    func compress(
        image: UIImage,
        maxSize: Int = Constraints.targetFileSize,
        maxDimension: CGFloat = Constraints.maxDimension
    ) throws -> Data {
        let startTime = Date()
        
        // 원본 이미지 크기 로깅
        if let originalData = image.jpegData(compressionQuality: 1.0) {
            print("📸 Original image size: \(formatFileSize(originalData.count))")
            print("📐 Original dimensions: \(Int(image.size.width))x\(Int(image.size.height))")
        }
        
        // 리사이징
        let resizedImage = resizeImage(image, maxDimension: maxDimension)
        print("✂️ Resized dimensions: \(Int(resizedImage.size.width))x\(Int(resizedImage.size.height))")
        
        // 압축
        var compression: CGFloat = 1.0
        var compressedData = resizedImage.jpegData(compressionQuality: compression)!
        
        while compressedData.count > maxSize && compression > Constraints.minimumQuality {
            compression -= 0.1
            if let newData = resizedImage.jpegData(compressionQuality: compression) {
                compressedData = newData
                print("🔄 Trying compression quality: \(String(format: "%.1f", compression))")
                print("📦 Current size: \(formatFileSize(compressedData.count))")
            }
        }
        
        print("""
        ✅ Compression completed:
        • Duration: \(String(format: "%.2f", Date().timeIntervalSince(startTime)))s
        • Final size: \(formatFileSize(compressedData.count))
        • Compression ratio: \(String(format: "%.1f", Float(compressedData.count) / Float(image.jpegData(compressionQuality: 1.0)?.count ?? 1) * 100))%
        """)
        
        return compressedData
    }
    
    func compressForAPI(_ image: UIImage) throws -> Data {
        return try compress(
            image: image,
            maxSize: Constraints.targetFileSize,
            maxDimension: Constraints.maxDimension
        )
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        var targetSize = originalSize
        
        // 최소/최대 크기 제한 적용
        if originalSize.width > maxDimension || originalSize.height > maxDimension {
            let widthRatio = maxDimension / originalSize.width
            let heightRatio = maxDimension / originalSize.height
            let ratio = min(widthRatio, heightRatio)
            targetSize = CGSize(
                width: max(Constraints.minDimension, originalSize.width * ratio),
                height: max(Constraints.minDimension, originalSize.height * ratio)
            )
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

// MARK: - Usage Example
extension ImageCompressor {
    static func example() {
        guard let image = UIImage(named: "example") else { return }
        
        do {
            // Basic compression
            let compressedData = try ImageCompressor.shared.compress(image: image)
            print("Compressed size: \(compressedData.count) bytes")
            
            // Compression for API
            let apiReadyData = try ImageCompressor.shared.compressForAPI(image)
            print("API-ready size: \(apiReadyData.count) bytes")
            
        } catch {
            print("Compression failed: \(error)")
        }
    }
}
