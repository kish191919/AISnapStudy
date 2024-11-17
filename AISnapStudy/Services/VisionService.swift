// Services/VisionService.swift

import Vision
import UIKit

// Vision 관련 에러 타입 정의
enum VisionError: Error {
    case invalidImage
    case processingFailed
    case noTextFound
    case unknown(Error)
}

class VisionService {
    static let shared = VisionService()
    
    private init() {}
    
    func extractText(from image: UIImage) async throws -> String {
        print("🔍 Starting universal text extraction...")
        
        guard let cgImage = image.cgImage else {
            print("❌ Failed to get CGImage from UIImage")
            throw VisionError.invalidImage
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        
        // 범용 텍스트 인식 설정
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        // recognitionLanguages를 설정하지 않음으로써
        // Vision이 모든 가능한 언어를 자동으로 감지하도록 함
        
        print("📝 Configured for universal text recognition")
        
        do {
            try requestHandler.perform([request])
            
            let observations = request.results ?? []
            print("📊 Found \(observations.count) text observations")
            
            var extractedTexts: [String] = []
            
            for observation in observations {
                if let candidate = observation.topCandidates(1).first {
                    let text = candidate.string
                    let confidence = candidate.confidence
                    
//                    print("""
//                        🔤 Extracted text segment:
//                        • Text: \(text)
//                        • Confidence: \(confidence)
//                        """)
                    
                    if confidence > 0.3 { // 신뢰도 임계값을 낮춤
                        extractedTexts.append(text)
                    }
                }
            }
            
            let finalText = extractedTexts.joined(separator: "\n")
//            print("✅ Final extracted text:\n\(finalText)")
            
            // 텍스트 검증
            guard !finalText.isEmpty else {
                print("⚠️ No valid text extracted")
                throw VisionError.noTextFound
            }
            
            return finalText
            
        } catch {
            print("❌ Text extraction failed: \(error.localizedDescription)")
            throw VisionError.processingFailed
        }
    }
}
