import UIKit
import Photos
import AVFoundation

public enum ImageSource {
   case camera
   case gallery
}

enum ImageServiceError: Error {
   case permissionDenied
   case unavailable
   case unknown(Error)
   case compressionFailed
}

public class ImageService {
    public static let shared = ImageService()
    
    private init() {}
    
    public struct VisionDetail {
        public static let maxDimension: CGFloat = 1024
        public static let maxFileSize = 1024 * 1024  // 100KB
        public static let compressionQuality: CGFloat = 0.9
    }
    
    func compressForAPI(_ image: UIImage) throws -> Data {
        // 이미지의 크기를 최대 치수에 맞게 조정
        let resizedImage = resize(image, to: VisionDetail.maxDimension)
        
        // 설정된 품질로 압축
        var compressedData = resizedImage.jpegData(compressionQuality: VisionDetail.compressionQuality)
        
        // 크기가 최대 파일 크기를 초과하는 경우, 품질을 낮춰서 추가 압축 시도
        var compressionQuality = VisionDetail.compressionQuality
        while let data = compressedData, data.count > VisionDetail.maxFileSize, compressionQuality > 0.1 {
            compressionQuality -= 0.1
            compressedData = resizedImage.jpegData(compressionQuality: compressionQuality)
        }
        
        guard let finalData = compressedData, finalData.count <= VisionDetail.maxFileSize else {
            throw NSError(domain: "ImageCompression", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to compress image to target size"])
        }
        
        print("Final compressed image size: \(finalData.count / 1024)KB with quality: \(compressionQuality)")
        return finalData
    }

    
    private func resize(_ image: UIImage, to maxDimension: CGFloat) -> UIImage {
        let aspectRatio = image.size.width / image.size.height
        let newSize: CGSize
        if image.size.width > image.size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    public enum OptimizationType {
        case openAIVision
        case general(maxSizeKB: Int)
    }
    
    @MainActor
    public func requestPermission(for source: ImageSource) async throws -> Bool {
        switch source {
        case .gallery:
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch status {
            case .authorized, .limited:
                return true
            case .notDetermined:
                return await withCheckedContinuation { continuation in
                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                        let isAuthorized = status == .authorized || status == .limited
                        print("Photo Library Authorization Status: \(status), Authorized: \(isAuthorized)")
                        continuation.resume(returning: isAuthorized)
                    }
                }
            case .denied, .restricted:
                print("Photo Library Access Denied or Restricted")
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    await MainActor.run {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                throw ImageServiceError.permissionDenied
            @unknown default:
                print("Unknown Photo Library Authorization Status")
                throw ImageServiceError.unknown(NSError(domain: "PhotoLibrary", code: -1))
            }
            
        case .camera:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                print("Camera Not Available")
                throw ImageServiceError.unavailable
            }
            
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                return true
            case .notDetermined:
                return await withCheckedContinuation { continuation in
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        print("Camera Authorization Status: \(granted)")
                        continuation.resume(returning: granted)
                    }
                }
            case .denied, .restricted:
                print("Camera Access Denied or Restricted")
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    await MainActor.run {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                throw ImageServiceError.permissionDenied
            @unknown default:
                print("Unknown Camera Authorization Status")
                throw ImageServiceError.unknown(NSError(domain: "Camera", code: -1))
            }
        }
    }
    
    public func optimizeForVision(_ image: UIImage) async throws -> (data: Data, tokens: Int) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let originalSize = image.size
        let originalData = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        
        // VisionDetail의 설정 값을 사용
        let targetSize = CGSize(width: VisionDetail.maxDimension, height: VisionDetail.maxDimension)
        let estimatedTokens = Int(VisionDetail.maxFileSize / 1024)  // 예측 토큰 수 계산
        
        let optimizedImage = try await optimizeImage(image, targetSize: targetSize)
        
        guard let optimizedData = optimizedImage.jpegData(compressionQuality: VisionDetail.compressionQuality) else {
            throw ImageServiceError.compressionFailed
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        printOptimizationMetrics(
            originalSize: originalSize,
            targetSize: targetSize,
            originalData: originalData,
            optimizedData: optimizedData.count,
            estimatedTokens: estimatedTokens,
            processingTime: totalTime
        )
        
        return (optimizedData, estimatedTokens)
    }
    
    public func compressImage(_ image: UIImage, optimization: OptimizationType) async throws -> Data {
        switch optimization {
        case .openAIVision:
            let result = try await optimizeForVision(image)
            return result.data
            
        case .general(let maxSizeKB):
            guard let originalImageData = image.jpegData(compressionQuality: 1.0) else {
                throw ImageServiceError.compressionFailed
            }
            
            var compression: CGFloat = 1.0
            var currentData = originalImageData
            
            while currentData.count > maxSizeKB * 1024 && compression > 0.1 {
                compression -= 0.1
                if let compressedData = image.jpegData(compressionQuality: compression) {
                    currentData = compressedData
                    print("Compression ratio \(compression): \(Double(currentData.count) / 1024.0)KB")
                }
            }
            
            if currentData.count > maxSizeKB * 1024 {
                let scale = sqrt(Double(maxSizeKB * 1024) / Double(currentData.count))
                let newSize = CGSize(
                    width: image.size.width * scale,
                    height: image.size.height * scale
                )
                
                print("Image resizing: \(newSize.width) x \(newSize.height)")
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                if let resizedImage = UIGraphicsGetImageFromCurrentImageContext(),
                   let finalData = resizedImage.jpegData(compressionQuality: compression) {
                    UIGraphicsEndImageContext()
                    print("Final compressed image size: \(Double(finalData.count) / 1024.0)KB")
                    return finalData
                }
                UIGraphicsEndImageContext()
                throw ImageServiceError.compressionFailed
            }
            
            print("Final compressed image size: \(Double(currentData.count) / 1024.0)KB")
            return currentData
        }
    }
    
    private func optimizeImage(_ image: UIImage, targetSize: CGSize) async throws -> UIImage {
        return await withCheckedContinuation { continuation in
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            
            let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
            let optimizedImage = renderer.image { context in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            
            continuation.resume(returning: optimizedImage)
        }
    }
    
    private func printOptimizationMetrics(
        originalSize: CGSize,
        targetSize: CGSize,
        originalData: Int,
        optimizedData: Int,
        estimatedTokens: Int,
        processingTime: TimeInterval
    ) {
        print("""
        📊 Image Optimization Results:
        • Original Size: \(Int(originalSize.width))x\(Int(originalSize.height))
        • Optimized Size: \(Int(targetSize.width))x\(Int(targetSize.height))
        • Original Data: \(ByteCountFormatter.string(fromByteCount: Int64(originalData), countStyle: .file))
        • Optimized Data: \(ByteCountFormatter.string(fromByteCount: Int64(optimizedData), countStyle: .file))
        • Estimated Tokens: \(estimatedTokens)
        • Processing Time: \(String(format: "%.3f", processingTime))s
        • Reduction: \(String(format: "%.1f", (1.0 - Double(optimizedData)/Double(originalData)) * 100))%
        """)
    }
}
