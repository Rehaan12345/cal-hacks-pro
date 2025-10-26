//
//  RecentEvent.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 26/10/25.
//
import Foundation

struct RecentEvent: Codable, Identifiable {
    let id = UUID()
    let date: String
    let time: String
    let incidentNumber: String
    let location: String
    let district: String
    let categorySFPD: String
    let description: String
    let resolution: String

    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case time = "Time"
        case incidentNumber = "Incident #"
        case location = "Location"
        case district = "District"
        case categorySFPD = "CategorySFPD"
        case description = "Description"
        case resolution = "Resolution"
    }
}
