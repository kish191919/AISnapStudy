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
        
        // Universal text recognition settings
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true // Enable automatic language detection
        
        print("📝 Configured for universal text recognition")
        
        do {
            try requestHandler.perform([request])
            
            let observations = request.results ?? []
            print("📊 Found \(observations.count) text observations")
            
            var textBlocks: [(text: String, location: CGRect)] = []
            
            for observation in observations {
                if let candidate = observation.topCandidates(1).first {
                    let text = candidate.string
                    let confidence = candidate.confidence
                    
                    if confidence > 0.2 {
                        textBlocks.append((text, observation.boundingBox))
                    }
                }
            }
            
            let finalText = processTextBlocks(textBlocks)
            
            guard !finalText.isEmpty else {
                print("⚠️ No valid text extracted")
                throw VisionError.noTextFound
            }
            
            print("✅ Successfully extracted text")
            return finalText
            
        } catch {
            print("❌ Text extraction failed: \(error.localizedDescription)")
            throw VisionError.processingFailed
        }
    }
    
    private func processTextBlocks(_ blocks: [(text: String, location: CGRect)]) -> String {
        // Sort blocks by their position on the page
        let sortedBlocks = blocks.sorted { (block1, block2) -> Bool in
            // Different lines (threshold for line height difference)
            if abs(block1.location.minY - block2.location.minY) > 0.05 {
                return block1.location.minY > block2.location.minY
            }
            // Same line - left to right
            return block1.location.minX < block2.location.minX
        }
        
        // Process and join text blocks
        let processedText = sortedBlocks
            .map { block in
                var text = block.text
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Fix common punctuation issues
                text = text.replacingOccurrences(of: "\\s*([.,!?])\\s*", with: "$1 ", options: .regularExpression)
                text = text.replacingOccurrences(of: "([.,!?])\\1+", with: "$1", options: .regularExpression)
                
                return text
            }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processedText
    }
}
