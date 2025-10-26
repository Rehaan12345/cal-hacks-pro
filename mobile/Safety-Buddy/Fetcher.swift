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
    @Published var recentEvents: [RecentEvent]?
    @Published var analysis: EventAnalysis?

    
    init(latitude: Double, longitude: Double, neighborhood: String, city: String = "San Francisco", state: String = "California") {
        self.latitude = latitude
        self.longitude = longitude
        self.neighborhood = neighborhood
        self.city = city
        self.state = state
        
        setCrimeRecommendations()
        setNearbyPoliceStations()
        setRecentEvents()
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
        
        let profile = UserProfile.load()
        let userStats: [String: String] = profile?.toAdditionalProps() ?? [:]
        
        // Build JSON body
        let body: [String: Any] = [
                "neighborhood": adaptedNeighborhood,
                "city": city,
                "state": state,
                "user_stats": userStats,
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
            while (policeStations == nil || recentEvents == nil) {
                try? await Task.sleep(nanoseconds: 20)
            }
            
            self.dangerScore = Int(safetyMetric(crimeCount: recentEvents!.count, numPStations: policeStations!.count, safestEarliestTime: analysis!.safestHours.first ?? 6, safestLatestTime: analysis!.safestHours.last ?? 18))
            
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
        crimeCount: Int,
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
        let normalizedCrime = min(Double(crimeCount) / 150, 3.0)
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
    
    // MARK: - Recent Events

    func setRecentEvents() {
        Task {
            self.recentEvents = try? await fetchRecentEvents()
            
            self.analysis = analyzeRecentEvents()
        }
    }

    func fetchRecentEvents() async throws -> [RecentEvent] {
        guard let encodedNeighborhood = adaptedNeighborhood.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://cal-hacks-pro-backend.vercel.app/scraper/scrape-civic-hub/?neighborhood=\(encodedNeighborhood)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Try a forgiving decode
        do {
            let decoder = JSONDecoder()
            let events = try decoder.decode([RecentEvent].self, from: data)
            return events
        } catch {
            // Fallback: decode loosely, skipping bad objects
            let rawArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            let validData = rawArray.compactMap { dict -> RecentEvent? in
                guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
                return try? JSONDecoder().decode(RecentEvent.self, from: jsonData)
            }
            return validData
        }
    }
    
    func analyzeRecentEvents() -> EventAnalysis? {
        guard let recentEvents = recentEvents, !recentEvents.isEmpty else {
            return nil
        }
        
        // === 1️⃣ Count by category
        let categoryCounts = Dictionary(grouping: recentEvents.compactMap { $0.categorySFPD }) { $0 }
            .mapValues { $0.count }
        let primaryCategory = categoryCounts.max(by: { $0.value < $1.value })?.key ?? "Unknown"
        
        // === 2️⃣ Group by hour
        var hourCounts: [Int: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        for event in recentEvents {
            guard let date = formatter.date(from: event.time) else { continue }
            let hour = Calendar.current.component(.hour, from: date)
            hourCounts[hour, default: 0] += 1
        }
        
        // Sort by count
        let sortedByCount = hourCounts.sorted(by: { $0.value < $1.value })
        let safestHours = sortedByCount.prefix(3).map { $0.key }
        let riskiestHours = sortedByCount.suffix(3).map { $0.key }.reversed()
        
        // === 3️⃣ Compare to current time
        let nowHour = Calendar.current.component(.hour, from: Date())
        let currentIncidents = hourCounts[nowHour] ?? 0
        
        // Find next hours where risk changes
        let nextSafer = (1...6).compactMap { offset -> Int? in
            let h = (nowHour + offset) % 24
            guard let count = hourCounts[h], count < currentIncidents else { return nil }
            return h
        }.first
        
        let nextRiskier = (1...6).compactMap { offset -> Int? in
            let h = (nowHour + offset) % 24
            guard let count = hourCounts[h], count > currentIncidents else { return nil }
            return h
        }.first
        
        // Determine current trend
        let trend: EventAnalysis.RiskTrend
        if let nextSafer = nextSafer, let nextRiskier = nextRiskier {
            trend = nextSafer < nextRiskier ? .saferSoon : .riskierSoon
        } else if nextSafer != nil {
            trend = .saferSoon
        } else if nextRiskier != nil {
            trend = .riskierSoon
        } else {
            trend = .stable
        }
        
        return EventAnalysis(
            primaryCategory: primaryCategory,
            safestHours: safestHours,
            riskiestHours: [Int](riskiestHours),
            nextSaferHour: nextSafer,
            nextRiskierHour: nextRiskier,
            currentRiskTrend: trend
        )
    }

}
