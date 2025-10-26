//
//  PoliceStation.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 25/10/25.
//

import Foundation

struct PoliceStation: Codable, Identifiable {
    let id = UUID()  // for SwiftUI List use
    let title: String
    let address: String
    let phone: String?
    let location: Coordinates
    let distance: Double
}

struct Coordinates: Codable {
    let lat: Double
    let lng: Double
}
