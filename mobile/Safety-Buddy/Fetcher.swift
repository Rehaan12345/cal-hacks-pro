//
//  Fetcher.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 25/10/25.
//

import Foundation
import Combine
import MapKit

class LocationMetadata: ObservableObject {
    let latitude: Double
    let longitude: Double
    let neighborhood: String
    let city: String
    let state: String
    
    @Published var crimeRecsResponse: [String]?
    @Published var policeStations: [PoliceStation]?
    @Published var dangerScore: Int?
    
    init(latitude: Double, longitude: Double, neighborhood: String, city: String = "San Francisco", state: String = "California") {
        self.latitude = latitude
        self.longitude = longitude
        self.neighborhood = neighborhood
        self.city = city
        self.state = state
        
        setCrimeRecommendations()
        setNearbyPoliceStations()
        setDangerScore()
    }
    
    @Published var safetyState = SafetyState.loading
    
    var currentISODate: String {
        let date = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoString = formatter.string(from: date)
        
        return isoString
    }
    
    var adaptedNeighborhood: String {
        guard neighborhood != "Fashion District" else { return neighborhood }
        
        return neighborhood.replacingOccurrences(of: " District", with: "")
    }
    
    func setCrimeRecommendations() {
        Task {
            self.crimeRecsResponse = try? await fetchCrimeRecommendations().recommendations
        }
    }
    
    func fetchCrimeRecommendations() async throws -> CrimeData {
        guard let url = URL(string: "https://cal-hacks-pro-backend.vercel.app/scraper/crime-recs/") else {
            throw URLError(.badURL)
        }
        
        // Build JSON body
        let body: [String: Any] = [
                "neighborhood": adaptedNeighborhood,
                "city": city,
                "state": state,
                "user_stats": [
                    "additionalProp1": "",
                    "additionalProp2": ""
                ],
                "transport": "walk",
                "time": currentISODate
            ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Failed")
            throw URLError(.badServerResponse)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(CrimeData.self, from: data)
            
            return decodedResponse
        } catch {
            dump(error)
            throw URLError(.unknown)
        }
    }
    
    // MARK: - Police Stations
        func setNearbyPoliceStations() {
            Task {
                self.policeStations = try? await findNearbyPoliceStations()
            }
        }
        
    func findNearbyPoliceStations(
        radiusInMeters: Double = 3.200  // 5 km radius
        ) async throws -> [PoliceStation] {
            
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: location.coordinate,
                                            latitudinalMeters: radiusInMeters,
                                            longitudinalMeters: radiusInMeters)
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "police station"
            request.region = region
            
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            let stations = response.mapItems.compactMap { item -> PoliceStation? in
                guard let name = item.name,
                      let coordinate = item.placemark.location?.coordinate else {
                    return nil
                }
                
                // Calculate distance from center
                let itemLocation = CLLocation(latitude: coordinate.latitude,
                                              longitude: coordinate.longitude)
                let distance = location.distance(from: itemLocation)
                
                return PoliceStation(
                    title: name,
                    address: item.placemark.title ?? "Unknown address",
                    phone: item.phoneNumber,
                    location: Coordinates(lat: coordinate.latitude,
                                          lng: coordinate.longitude),
                    distance: (distance * 0.00062)
                )
            }
            
            // Sort by closest first
            return stations.filter( { $0.distance <= 2}).sorted { $0.distance < $1.distance }
        }
    
    func setDangerScore() {
        Task {
            while (policeStations == nil) {
                try? await Task.sleep(nanoseconds: 20)
            }
            
            self.dangerScore = Int(safetyMetric(crimeCount: 55, numPStations: policeStations!.count, safestEarliestTime: 5, safestLatestTime: 19))
            
            if let dangerScore {
                switch(dangerScore) {
                case 1...60:
                    self.safetyState = .safe
                case 61...75:
                    self.safetyState = .moderate
                default:
                    self.safetyState = .danger
                }
            }
        }
    }

    func safetyMetric (
        crimeCount: Double,
        numPStations: Int,
        safestEarliestTime: Int,
        safestLatestTime: Int
    ) -> Double {
        var score: Double = 18.0

        // === Time-based danger adjustment ===
        let now = Date()
        let calendar = Calendar.current
        let currHour = calendar.component(.hour, from: now)
        
        if !(safestEarliestTime...safestLatestTime).contains(currHour) {
            score += 5
        } else if (safestEarliestTime - 2)...safestLatestTime ~= currHour {
            score += 3
        }
        
        // === Day of week ===
        let weekday = calendar.component(.weekday, from: now) // Sunday = 1
        if weekday >= 2 && weekday <= 6 {
            score += 1 // Weekday
        } else {
            score += 3 // Weekend
        }
        
        // === Police presence ===
        if numPStations == 0 {
            score += 10
        } else if numPStations < 5 {
            score += Double(5 - numPStations) * 2.2
        }
        
        // === Crime-based scaling ===
        let normalizedCrime = min(crimeCount / 150.0, 3.0)
        let crimeDanger = pow(normalizedCrime, 1.55) * 20.0
        score += crimeDanger
        
        // === Normalize and constrain ===
        score = max(15.0, min(score, 88.0))
        
        // === Random variation for realism ===
        let randomOffset = Double.random(in: -1.0...1.0)
        score += randomOffset
        
        // Round and bound 0–100
        score = max(0.0, min((score * 10.0).rounded() / 10.0, 100.0))
        
        return score
    }

}
