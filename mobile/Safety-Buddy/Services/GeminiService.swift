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
        - whether they appear wealthy or not (key Wealth indicators)
        - any valuable items visible in the image (watches, jewelry, phones, bags, etc.)
        - any other notable observations
        
        The following keys MUST be present:
            age: String (e.g., "25-30", "18-22")
            gender: String (e.g., "Male", "Female", "Non-binary")
            wealthIndicators: [String] (e.g., ["Designer clothing", "Expensive watch"])
            valuableItems: [String] (e.g., ["iPhone", "Gold watch", "Designer bag"])
            riskLevel: String ("low", "medium", or "high")
        
        YOU CANNOT DO ANYTHING BUT JSON IN THE RESPONSE. No markdown, no code blocks, just pure JSON.
        """
        
        // LAVA ENDPOINT CALL (for appearances)
        // This maintains compatibility with existing infrastructure
        Task {
            await performLavaAPICall(base64Image: base64Image, systemPrompt: systemPrompt, userPrompt: userPrompt)
        }
        
        // ACTUAL OPENAI VISION API CALL
        // Using OpenAI Responses API for direct image analysis
        return try await performOpenAIVisionAnalysis(base64Image: base64Image, userPrompt: userPrompt)
    }
    
    // Lava API integration (legacy support)
    private func performLavaAPICall(base64Image: String, systemPrompt: String, userPrompt: String) async {
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
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted),
              let url = URL(string: APIConfig.lavaForwardURL) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.lavaForwardToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60
        
        do {
            print("[Lava] Sending request to Lava endpoint...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[Lava] Response status: \(httpResponse.statusCode)")
                if let requestId = httpResponse.value(forHTTPHeaderField: "x-lava-request-id") {
                    print("[Lava] Request ID: \(requestId)")
                }
            }
            
            // Log response but don't use it
            if let responseStr = String(data: data, encoding: .utf8) {
                print("[Lava] Response received (not used): \(responseStr.prefix(200))...")
            }
        } catch {
            // Silently handle Lava errors - we don't rely on this endpoint
            print("[Lava] Error (ignored): \(error.localizedDescription)")
        }
    }
    
    // Direct OpenAI Vision API call using Chat Completions
    private func performOpenAIVisionAnalysis(base64Image: String, userPrompt: String) async throws -> UserProfile {
        // Prepare request using OpenAI Chat Completions API with vision
        let requestBody: [String: Any] = [
            "model": APIConfig.visionModel,
            "messages": [
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
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "high"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1000
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted) else {
            throw GeminiError.requestEncodingFailed
        }
        
        guard let url = URL(string: APIConfig.openAIProviderEndpoint) else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60
        
        print("[OpenAI] Sending vision analysis request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        print("[OpenAI] Response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
            print("[OpenAI] Error response: \(errorBody)")
            throw GeminiError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Log raw response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            print("[OpenAI] Raw response: \(responseStr)")
        }
        
        // Parse OpenAI Chat Completions response
        let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        
        guard let responseText = chatResponse.choices.first?.message.content else {
            throw GeminiError.noResponseText
        }
        
        print("[OpenAI] Vision analysis result:\n\(responseText)")
        
        // Parse JSON from the response
        return try parseProfileFromJSON(responseText)
    }
    
    // Parse the LLM's JSON response into UserProfile
    private func parseProfileFromJSON(_ jsonString: String) throws -> UserProfile {
        // Clean up the response - remove markdown code blocks if present
        var cleanedJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks
        if cleanedJSON.hasPrefix("```json") {
            cleanedJSON = cleanedJSON.replacingOccurrences(of: "```json", with: "")
        }
        if cleanedJSON.hasPrefix("```") {
            cleanedJSON = cleanedJSON.replacingOccurrences(of: "```", with: "")
        }
        if cleanedJSON.hasSuffix("```") {
            cleanedJSON = String(cleanedJSON.dropLast(3))
        }
        cleanedJSON = cleanedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw GeminiError.jsonParsingFailed
        }
        
        // Parse JSON
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw GeminiError.jsonParsingFailed
        }
        
        print("[Parser] Parsed JSON object: \(jsonObject)")
        
        var profile = UserProfile()
        profile.age = jsonObject["age"] as? String
        profile.gender = jsonObject["gender"] as? String
        profile.wealthIndicators = jsonObject["wealthIndicators"] as? [String] ?? []
        profile.valuableItems = jsonObject["valuableItems"] as? [String] ?? []
        profile.riskLevel = jsonObject["riskLevel"] as? String ?? "medium"
        profile.extractedAt = Date()
        
        // Determine SF Symbol based on gender
        if let gender = profile.gender?.lowercased() {
            if gender.contains("female") || gender.contains("woman") {
                profile.sfSymbolIcon = "person.fill"
            } else if gender.contains("male") || gender.contains("man") {
                profile.sfSymbolIcon = "person.fill"
            } else {
                profile.sfSymbolIcon = "person.fill"
            }
        }
        
        print("[Parser] Profile created successfully:")
        print("  Age: \(profile.age ?? "N/A")")
        print("  Gender: \(profile.gender ?? "N/A")")
        print("  Wealth Indicators: \(profile.wealthIndicators)")
        print("  Valuable Items: \(profile.valuableItems)")
        print("  Risk Level: \(profile.riskLevel)")
        
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

