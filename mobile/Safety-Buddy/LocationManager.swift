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

import Foundation
import CoreLocation
import MapKit

@MainActor
class LocationManager: NSObject, ObservableObject {
    // MARK: - Core Managers
    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()
    private let geocoder = CLGeocoder()
    
    // MARK: - Published Properties
    @Published var location: CLLocation?                          // The location shown on the map
    @Published var currentDeviceLocation: CLLocation?              // The actual GPS location
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    
    
    // Search
    @Published var searchQuery = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    // Geocoding
    @Published var neighborhoodName: String? = nil
    
    // MARK: - Private
    private var lastGeocodeTime: Date?
    
    // MARK: - Computed
    /// Returns true if the map’s displayed location is within 10m of the real device location
    var isAtActualLocation: Bool {
        guard let current = currentDeviceLocation, let displayed = location else {
            return false
        }
        return current.distance(from: displayed) < 10
    }
    
    // MARK: - Init
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // meters
        locationManager.headingFilter = 5   // degrees
        
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        
        // Default region (San Francisco)
        let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            latitudinalMeters: 50000,
            longitudinalMeters: 50000
        )
        searchCompleter.region = defaultRegion
    }
    
    // MARK: - Location Permissions & Updates
    
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
    
    func resetToCurrentLocation() {
        startUpdating()
        if let current = currentDeviceLocation {
            location = current
        }
    }
    
    // MARK: - Search
    
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
        if let completion = searchResult.completion {
            let searchRequest = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: searchRequest)
            
            search.start { [weak self] response, error in
                guard let self = self else { return }
                if let item = response?.mapItems.first {
                    let selectedLocation = CLLocation(
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude
                    )
                    DispatchQueue.main.async {
                        self.location = selectedLocation
                        self.searchResults = []
                        self.searchQuery = ""
                        self.reverseGeocode(location: selectedLocation)
                    }
                } else if let error = error {
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
            self.searchResults = []
            self.searchQuery = ""
            self.reverseGeocode(location: selectedLocation)
        }
    }
}

// MARK: - CLLocationManagerDelegate

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
        guard let newLocation = locations.last else { return }
        
        // Update real GPS location
        self.currentDeviceLocation = newLocation
        isLoading = false
        
        // If user hasn't selected another location, keep map following user
        if isAtActualLocation || location == nil {
            self.location = newLocation
        }
        
        // Update search region
        let region = MKCoordinateRegion(
            center: newLocation.coordinate,
            latitudinalMeters: 50000,
            longitudinalMeters: 50000
        )
        searchCompleter.region = region
        
        // Reverse geocode for neighborhood name
        reverseGeocode(location: newLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as NSError
        if clError.code != 0 {
            print("Location error: \(error.localizedDescription)")
        }
        
        isLoading = false
        
        if location == nil {
            // Fallback to default location (San Francisco)
            location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        }
    }
}

// MARK: - Reverse Geocoding

extension LocationManager {
    private func reverseGeocode(location: CLLocation) {
        // Avoid spamming requests
        if let lastTime = lastGeocodeTime,
           Date().timeIntervalSince(lastTime) < 5 {
            return
        }
        lastGeocodeTime = Date()
        
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let placemark = placemarks?.first {
                let neighborhood = placemark.subLocality
                let city = placemark.locality
                let name = neighborhood ?? city ?? "Unknown"
                
                DispatchQueue.main.async {
                    self.neighborhoodName = name
                    print("📍 Neighborhood: \(name)")
                }
            } else if let error = error {
                print("Reverse geocode failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        print("✅ Got \(completer.results.count) search results")
        
        let results = completer.results.prefix(10).compactMap { completion -> SearchResult? in
            SearchResult(
                title: completion.title,
                subtitle: completion.subtitle,
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
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
