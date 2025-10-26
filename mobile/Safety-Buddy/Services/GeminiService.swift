//
//  GeminiService.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/25/25.
//

import Foundation
import UIKit

class GeminiService {
    static let shared = GeminiService()
    
    private init() {}
    
    // Analyze photo and extract user features
    func analyzePhoto(_ image: UIImage) async throws -> UserProfile {
        // Resize image to optimize for model (reduce payload size)
        let resizedImage = resizeImage(image, maxDimension: 768)
        
        // Convert image to base64 JPEG
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageConversionFailed
        }
        let base64Image = imageData.base64EncodedString()
        print("[AIAnalysis] Image data bytes: \(imageData.count), base64 length: \(base64Image.count)")
        
        // Build instructions and payload for GPT
        let systemPrompt = "You are a safety assistant that analyzes user selfies to identify valuables and personal risk indicators. Always return compact JSON with the requested fields. You must describe the person in json with gender, race, hair color etc"
        let userPrompt = """
        Review the person in this photo and return:
        - estimated age range
        - perceived gender
        - whether they appear wealthy or not (key Wealth indicar
        - any other notable observations
        
        The following keya MUST be present.
            var age: String?
            var gender: String?
            var wealthIndicators: [String]
            var valuableItems: [String]
            var riskLevel: String // "low", "medium", "high"
        
        
        YOU CANNOT DO ANYTHING BUT JSON IN THE RESPONSE. No markdown.
        """
        
        let message: [[String: Any]] = [
            [
                "role": "system",
                "content": systemPrompt
            ],
            [
                "role": "user",
                "content": [
                    [
                        "type": "text", 
                        "text": userPrompt
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": APIConfig.gptModel,
            "messages": message,
            "temperature": APIConfig.defaultTemperature,
            "max_completion_tokens": APIConfig.maxTokens,
            "stream": false
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted) else {
            throw GeminiError.requestEncodingFailed
        }
        
        // Debug: Print the request body (excluding full base64 for readability)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            let truncated = jsonString.count > 2000 
                ? String(jsonString.prefix(1500)) + "\n... [truncated] ..." 
                : jsonString
            print("[AIAnalysis] Request body:\n\(truncated)")
        }
        
        // Create URL request through Lava forwarding
        guard let url = URL(string: APIConfig.lavaForwardURL) else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.lavaForwardToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60 // allow extra time for image analysis
        
        // Make the request
        print("[AIAnalysis] Sending request to: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        print("[AIAnalysis] Response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
            print("[AIAnalysis] Error response: \(errorBody)")
            throw GeminiError.apiError(statusCode: httpResponse.statusCode)
        }
        print(String(data: data, encoding: .utf8))
        // Parse OpenAI chat response
        let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        
        guard let responseText = chatResponse.choices.first?.message.content else {
            throw GeminiError.noResponseText
        }
        
        print("LLM response dictionary:\n\(responseText)")
        
        var profile = UserProfile()
        
        if let requestId = httpResponse.value(forHTTPHeaderField: "x-lava-request-id") {
            print("Lava request id: \(requestId)")
        }
        
        return profile
    }
    
    // Helper function to resize image to optimal size for the provider
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        let ratio = size.width / size.height
        let newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Request/Response Structures

private struct OpenAIChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    let choices: [Choice]
}

// Retained only for reference if structured parsing is reintroduced in the future
// private struct ExtractedUserData: Codable { ... }

// Error types
enum GeminiError: LocalizedError {
    case imageConversionFailed
    case requestEncodingFailed
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case noResponseText
    case jsonParsingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to JPEG data"
        case .requestEncodingFailed:
            return "Failed to encode request body"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode):
            return "API error with status code: \(statusCode)"
        case .noResponseText:
            return "No text in API response"
        case .jsonParsingFailed:
            return "Failed to parse JSON response"
        }
    }
}

