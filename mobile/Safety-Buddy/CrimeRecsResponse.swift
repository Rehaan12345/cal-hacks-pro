//
//  CrimeRecsResponse.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 25/10/25.
//


import Foundation

struct CrimeRecsResponse: Codable {
    let status: Int
    let data: CrimeData
}

struct CrimeData: Codable {
    let safety_analysis: SafetyAnalysis
}

struct SafetyAnalysis: Codable {
    let overall_safety_level: String
    let safest_time_windows: TimeWindow
    let highest_risk_time_windows: RiskTimeWindows
    let recommendations_by_profile: RecommendationsByProfile
    let crime_patterns_observed: CrimePatterns
    let neighborhood_specific_risks: NeighborhoodRisks
}

struct TimeWindow: Codable {
    let earliest_safe_time: String
    let latest_safe_time: String
    let reasoning: String
}

struct RiskTimeWindows: Codable {
    let evening_night: RiskWindow
    let early_morning: RiskWindow
}

struct RiskWindow: Codable {
    let time_range: String
    let risk_level: String
    let primary_concerns: [String]
}

struct RecommendationsByProfile: Codable {
    let expensive_jewelry_clothing: ProfileRecommendation
    let inexpensive_jewelry_clothing: ProfileRecommendation
    let general_precautions: GeneralPrecautions
}

struct ProfileRecommendation: Codable {
    let safety_level: String
    let safest_hours: String
    let avoid_hours: String
    let high_risk_areas: [String]
    let specific_threats: [String]
}

struct GeneralPrecautions: Codable {
    let safety_level: String
    let safest_hours: String
    let moderate_risk_hours: String
    let high_risk_hours: String
}

struct CrimePatterns: Codable {
    let most_common_incidents: [String]
    let peak_crime_hours: [String]
    let safest_hours: [String]
}

struct NeighborhoodRisks: Codable {
    let highest_crime_areas: [String]
    let moderate_crime_areas: [String]
    let lower_crime_areas: [String]
}
