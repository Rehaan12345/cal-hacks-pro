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

extension UserProfile {
    func toAdditionalProps() -> [String: String] {
        var props: [String] = []
        
        if let age = age { props.append("Age: \(age)") }
        if let gender = gender { props.append("Gender: \(gender)") }
        
        if !wealthIndicators.isEmpty {
            props.append("Wealth Indicators: \(wealthIndicators.joined(separator: ", "))")
        }
        
        if !valuableItems.isEmpty {
            props.append("Valuable Items: \(valuableItems.joined(separator: ", "))")
        }
        
        props.append("Symbol: \(sfSymbolIcon)")
        props.append("Risk Level: \(riskLevel)")
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        props.append("Extracted At: \(formatter.string(from: extractedAt))")
        
        // Turn into ["additionalProp1": "…", "additionalProp2": "…", …]
        var dict: [String: String] = [:]
        for (index, prop) in props.enumerated() {
            dict["additionalProp\(index + 1)"] = prop
        }
        return dict
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

