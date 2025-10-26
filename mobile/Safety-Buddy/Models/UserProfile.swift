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
    
    private static let userDefaultsKey = "userProfile"
    
    init() {
        self.age = nil
        self.gender = nil
        self.wealthIndicators = []
        self.valuableItems = []
        self.sfSymbolIcon = "person.fill"
        self.riskLevel = "medium"
        self.extractedAt = Date()
    }
    
    // MARK: - UserDefaults Persistence
    
    /// Save the profile to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
            print("✅ User profile saved to UserDefaults")
        } else {
            print("❌ Failed to encode user profile")
        }
    }
    
    /// Load the profile from UserDefaults
    static func load() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            print("ℹ️ No saved user profile found")
            return nil
        }
        print("✅ User profile loaded from UserDefaults")
        return profile
    }
    
    /// Clear the saved profile from UserDefaults
    static func clear() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("🗑️ User profile cleared from UserDefaults")
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

