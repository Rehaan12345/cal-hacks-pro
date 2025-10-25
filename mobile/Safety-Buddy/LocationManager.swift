//
//  LocationManager.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/24/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.headingFilter = 5 // Update every 5 degrees
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

