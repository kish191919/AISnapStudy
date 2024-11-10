
// Services/ImageService.swift
import UIKit
import Photos
import AVFoundation

// ImageSource enum 추가
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
                // 설정으로 이동하는 알림 표시
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
            // 카메라 사용 가능 여부 확인
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
                // 설정으로 이동하는 알림 표시
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
   @MainActor
   private func requestCameraPermission() async throws -> Bool {
       // 먼저 카메라가 사용 가능한지 확인
       guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
           throw ImageServiceError.unavailable
       }
       
       let status = AVCaptureDevice.authorizationStatus(for: .video)
       switch status {
       case .authorized:
           return true
       case .notDetermined:
           return await withCheckedContinuation { continuation in
               AVCaptureDevice.requestAccess(for: .video) { granted in
                   continuation.resume(returning: granted)
               }
           }
       default:
           throw ImageServiceError.permissionDenied
       }
   }
   
   @MainActor
   private func requestPhotoLibraryPermission() async throws -> Bool {
       let status = PHPhotoLibrary.authorizationStatus()
       switch status {
       case .authorized, .limited:
           return true
       case .notDetermined:
           return await withCheckedContinuation { continuation in
               PHPhotoLibrary.requestAuthorization { status in
                   continuation.resume(returning: status == .authorized || status == .limited)
               }
           }
       default:
           throw ImageServiceError.permissionDenied
       }
   }
   
   public func compressImage(_ image: UIImage, maxSizeKB: Int = 1000) throws -> Data {
       // 원본 이미지 크기 로깅
       guard let originalImageData = image.jpegData(compressionQuality: 1.0) else {
           throw ImageServiceError.compressionFailed
       }
       print("원본 이미지 크기: \(Double(originalImageData.count) / 1024.0)KB")
       print("원본 이미지 dimensions: \(image.size.width) x \(image.size.height)")
       
       var compression: CGFloat = 1.0
       var currentData = originalImageData
       
       while currentData.count > maxSizeKB * 1024 && compression > 0.1 {
           compression -= 0.1
           if let compressedData = image.jpegData(compressionQuality: compression) {
               currentData = compressedData
               print("압축률 \(compression): \(Double(currentData.count) / 1024.0)KB")
           }
       }
       
       if currentData.count > maxSizeKB * 1024 {
           // 최대한 압축해도 목표 크기를 넘는 경우
           // 이미지 크기 자체를 줄임
           let scale = sqrt(Double(maxSizeKB * 1024) / Double(currentData.count))
           let newSize = CGSize(
               width: image.size.width * scale,
               height: image.size.height * scale
           )
           
           print("이미지 리사이징: \(newSize.width) x \(newSize.height)")
           
           UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
           image.draw(in: CGRect(origin: .zero, size: newSize))
           if let resizedImage = UIGraphicsGetImageFromCurrentImageContext(),
              let finalData = resizedImage.jpegData(compressionQuality: compression) {
               UIGraphicsEndImageContext()
               print("최종 압축 이미지 크기: \(Double(finalData.count) / 1024.0)KB")
               return finalData
           }
           UIGraphicsEndImageContext()
           throw ImageServiceError.compressionFailed
       }
       
       print("최종 압축 이미지 크기: \(Double(currentData.count) / 1024.0)KB")
       return currentData
   }
}
