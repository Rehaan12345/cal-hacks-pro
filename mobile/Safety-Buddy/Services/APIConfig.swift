//
//  APIConfig.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/25/25.
//

import Foundation

struct APIConfig {
    // Lava forwarding
    static let lavaBaseURL = "https://api.lavapayments.com/v1"
    static let lavaForwardToken = "eyJzZWNyZXRfa2V5IjoiYWtzX2xpdmVfa1doSkdUVTB2UnNWcUxKMGpwQ1FSWkxmMEw5RFJ5OHhRY1R2Tm9iNTZxTExRMHpmQlF1dGRyLSIsImNvbm5lY3Rpb25fc2VjcmV0IjoiY29uc19saXZlX1RpUTZocUM0VUZidzROSzRrc2J5M1ZrVmpXXzVld1pLc0hGWk1sVVpaeHRZaVFRNXl0QmRqaiIsInByb2R1Y3Rfc2VjcmV0IjoicHNfbGl2ZV9xeG53NHB5MU1ZSFdiQm9RVXlrR05BeHZYbU93YXlIT0lNUlhtYmFJSUhmU3hGUHBQaklfdHVOTSJ9"
    
    // OpenAI provider configuration
    static let gptModel = "gpt-5"
    static let visionModel = "gpt-4o"  // Use gpt-4o for vision analysis
    static let openAIProviderEndpoint = "https://api.openai.com/v1/chat/completions"
    static let openAIAPIKey = "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" 
    static let defaultTemperature: Double = 1
    static let maxTokens: Int = 102400
    
    // Forwarding URL (Lava forwards requests to OpenAI)
    static var lavaForwardURL: String {
        let encodedEndpoint = openAIProviderEndpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? openAIProviderEndpoint
        return "\(lavaBaseURL)/forward?u=\(encodedEndpoint)"
    }
}

