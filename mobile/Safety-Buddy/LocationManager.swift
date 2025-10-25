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
    let completion: MKLocalSearchCompletion?
    
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D, completion: MKLocalSearchCompletion? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.completion = completion
    }
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
        
        // Set a default region for search (San Francisco Bay Area)
        // This will be updated when user location is available
        let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            latitudinalMeters: 50000,
            longitudinalMeters: 50000
        )
        searchCompleter.region = defaultRegion
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
        print("🔍 Searching for: \(query)")
        searchCompleter.queryFragment = query
    }
    
    func selectLocation(_ searchResult: SearchResult) {
        // If we have a completion, resolve it to get accurate coordinates
        if let completion = searchResult.completion {
            let searchRequest = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: searchRequest)
            
            Task {
                do {
                    let response = try await search.start()
                    if let item = response.mapItems.first {
                        let selectedLocation = CLLocation(
                            latitude: item.placemark.coordinate.latitude,
                            longitude: item.placemark.coordinate.longitude
                        )
                        
                        await MainActor.run {
                            self.location = selectedLocation
                            self.searchResults = []
                            self.searchQuery = ""
                        }
                    }
                } catch {
                    print("Error resolving location: \(error.localizedDescription)")
                }
            }
        } else {
            // Use the coordinate directly if already resolved
            let selectedLocation = CLLocation(
                latitude: searchResult.coordinate.latitude,
                longitude: searchResult.coordinate.longitude
            )
            self.location = selectedLocation
            searchResults = []
            searchQuery = ""
        }
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
        
        // Update search region to make results more relevant
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 50000, // 50km radius
            longitudinalMeters: 50000
        )
        searchCompleter.region = region
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as NSError
        
        // Only log significant errors (ignore transient location unknown errors)
        if clError.code != 0 {
            print("Location error: \(error.localizedDescription)")
        }
        
        isLoading = false
        
        // Set a fallback location if we can't get user's location
        // This allows search to still work
        if location == nil {
            // Use a default location (San Francisco)
            location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        print("✅ Got \(completer.results.count) search results")
        
        // Convert completions to search results quickly
        let results = completer.results.prefix(10).compactMap { completion -> SearchResult? in
            // For most results, we can create a basic coordinate from the completion
            // This is much faster than doing individual searches
            return SearchResult(
                title: completion.title,
                subtitle: completion.subtitle,
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Will be resolved when selected
                completion: completion
            )
        }
        
        print("📍 Displaying \(results.count) results")
        
        DispatchQueue.main.async {
            self.searchResults = results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Search error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.searchResults = []
        }
    }
}

