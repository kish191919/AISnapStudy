import UIKit

enum ImageCompressorError: Error {
    case compressionFailed
    case invalidImage
}

class ImageCompressor {
    static let shared = ImageCompressor()
    
    private init() {}
    
    /// Compresses an image while trying to maintain reasonable quality
    /// - Parameters:
    ///   - image: Original UIImage
    ///   - maxSize: Maximum size in bytes (default: 1MB)
    ///   - maxDimension: Maximum width/height (default: 2048)
    /// - Returns: Compressed image data
    func compress(
        image: UIImage,
        maxSize: Int = 1024 * 1024, // 1MB
        maxDimension: CGFloat = 2048
    ) throws -> Data {
        // Step 1: Resize image if necessary
        let resized = resizeImage(image, maxDimension: maxDimension)
        
        // Step 2: Compress with decreasing quality until size is acceptable
        var compression: CGFloat = 1.0
        var data = resized.jpegData(compressionQuality: compression)
        
        while (data?.count ?? 0) > maxSize && compression > 0.1 {
            compression -= 0.1
            data = resized.jpegData(compressionQuality: compression)
        }
        
        guard let compressedData = data else {
            throw ImageCompressorError.compressionFailed
        }
        
        return compressedData
    }
    
    /// Compresses an image specifically for OpenAI API requirements
    /// - Parameter image: Original UIImage
    /// - Returns: Compressed image data suitable for API transmission
    func compressForAPI(_ image: UIImage) throws -> Data {
        // OpenAI recommends images under 20MB
        return try compress(
            image: image,
            maxSize: 10 * 1024 * 1024, // 10MB to be safe
            maxDimension: 2048
        )
    }
    
    // MARK: - Private Methods
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        var newSize = originalSize
        
        if originalSize.width > maxDimension || originalSize.height > maxDimension {
            let widthRatio = maxDimension / originalSize.width
            let heightRatio = maxDimension / originalSize.height
            let ratio = min(widthRatio, heightRatio)
            
            newSize = CGSize(
                width: originalSize.width * ratio,
                height: originalSize.height * ratio
            )
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resized
    }
    
    /// Estimates the file size of an image in bytes
    /// - Parameter image: Image to check
    /// - Returns: Estimated size in bytes
    func estimatedSize(_ image: UIImage) -> Int {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return 0 }
        return data.count
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
