//
//  LocationManager.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/24/25.
//

import Foundation
import CoreLocation
import MapKit
import Combine

struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
}

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()
    
    @Published var location: CLLocation?
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    
    // Search-related properties
    @Published var searchQuery = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.headingFilter = 5 // Update every 5 degrees
        
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        isLoading = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isLoading = false
    }
    
    // MARK: - Search Methods
    
    func updateSearchQuery(_ query: String) {
        searchQuery = query
        if query.isEmpty {
            searchResults = []
            return
        }
        searchCompleter.queryFragment = query
    }
    
    func selectLocation(_ searchResult: SearchResult) {
        let selectedLocation = CLLocation(
            latitude: searchResult.coordinate.latitude,
            longitude: searchResult.coordinate.longitude
        )
        self.location = selectedLocation
        searchResults = []
        searchQuery = ""
    }
    
    func resetToCurrentLocation() {
        startUpdating()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        case .denied, .restricted:
            stopUpdating()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        isLoading = false
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            var results: [SearchResult] = []
            
            for completion in completer.results {
                let searchRequest = MKLocalSearch.Request(completion: completion)
                let search = MKLocalSearch(request: searchRequest)
                
                do {
                    let response = try await search.start()
                    if let item = response.mapItems.first {
                        let result = SearchResult(
                            title: completion.title,
                            subtitle: completion.subtitle,
                            coordinate: item.placemark.coordinate
                        )
                        results.append(result)
                    }
                } catch {
                    // Silently continue on error
                    continue
                }
            }
            
            self.searchResults = results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search error: \(error.localizedDescription)")
    }
}

