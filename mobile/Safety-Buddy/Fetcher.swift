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
    
    init(latitude: Double, longitude: Double, neighborhood: String, city: String = "San Francisco", state: String = "California") {
        self.latitude = latitude
        self.longitude = longitude
        self.neighborhood = neighborhood
        self.city = city
        self.state = state
        
        setCrimeRecommendations()
        setNearbyPoliceStations()
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
        
        let date = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoString = formatter.string(from: date)
        
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
                "time": isoString
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
            return stations.sorted { $0.distance < $1.distance }
        }
    
}
