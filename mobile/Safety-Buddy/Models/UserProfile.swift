//
//  UserProfile.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/25/25.
//

import SwiftUI

struct UserProfile: Codable {
    var age: String?
    var gender: String?
    var wealthIndicators: [String]
    var valuableItems: [String]
    var sfSymbolIcon: String
    var riskLevel: String // "low", "medium", "high"
    var extractedAt: Date
    
    init() {
        self.age = nil
        self.gender = nil
        self.wealthIndicators = []
        self.valuableItems = []
        self.sfSymbolIcon = "person.fill"
        self.riskLevel = "medium"
        self.extractedAt = Date()
    }
}

// Response structure from Gemini
struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let text: String
            }
        }
    }
}

