// Utils/Helpers/ImageCompressor.swift
import UIKit

enum ImageCompressorError: Error {
    case compressionFailed
    case invalidImage
}

class ImageCompressor {
    static let shared = ImageCompressor()
    
    private enum Constraints {
        // 파일 크기 제한을 더 낮게 설정 (400KB로 줄임)
        static let targetFileSize = 400 * 1024  // 400KB
        // 최대 치수를 더 작게 설정 (800 -> 640)
        static let maxDimension: CGFloat = 640
        static let minDimension: CGFloat = 320
        // 최소 품질을 낮춤 (0.5 -> 0.3)
        static let minimumQuality: CGFloat = 0.3
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
        
        // 압축 시작 품질을 0.6에서 0.3으로 낮춤
        var compression: CGFloat = 0.3
        var compressedData = resizedImage.jpegData(compressionQuality: compression)!
        
        while compressedData.count > maxSize && compression > Constraints.minimumQuality {
            compression -= 0.1
            if let newData = resizedImage.jpegData(compressionQuality: compression) {
                compressedData = newData
                print("🔄 Trying compression quality: \(String(format: "%.1f", compression))")
                print("📦 Current size: \(formatFileSize(compressedData.count))")
            }
        }
        
        if compressedData.count > maxSize {
            let scale = sqrt(Double(maxSize) / Double(compressedData.count))
            let newSize = CGSize(
                width: resizedImage.size.width * scale,
                height: resizedImage.size.height * scale
            )
            
            let finalImage = UIGraphicsImageRenderer(size: newSize).image { _ in
                resizedImage.draw(in: CGRect(origin: .zero, size: newSize))
            }
            
            compressedData = finalImage.jpegData(compressionQuality: compression) ?? compressedData
            print("📐 Final resize dimensions: \(Int(newSize.width))x\(Int(newSize.height))")
        }
        
        print("""
        ✅ Compression completed:
        • Duration: \(String(format: "%.2f", Date().timeIntervalSince(startTime)))s
        • Final size: \(formatFileSize(compressedData.count))
        • Compression ratio: \(String(format: "%.1f", Float(compressedData.count) / Float(image.jpegData(compressionQuality: 1.0)?.count ?? 1) * 100))%
        """)
        
        return compressedData
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
