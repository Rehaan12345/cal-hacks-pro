//
//  CircularMapView.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/24/25.
//

import SwiftUI
import MapKit

struct CircularMapView: View {
    // MARK: - Properties
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var recenterTimer: Timer?
    
    // MARK: - Constants
    private let mapSize: CGFloat = 250
    private let zoomDistance: CLLocationDistance = 100
    private let cameraPitch: CGFloat = 0
    private let recenterDelay: TimeInterval = 2.0
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if let location = locationManager.location {
                mapView(for: location)
            } else {
                placeholderView
            }
        }
        .onAppear {
            startLocationTracking()
        }
        .onDisappear {
            locationManager.stopUpdating()
        }
    }
    
    // MARK: - Map View
    private func mapView(for location: CLLocation) -> some View {
        Map(position: $cameraPosition) {
            Annotation("", coordinate: location.coordinate) {
                locationIndicator
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {}
        .onMapCameraChange { _ in handleMapInteraction() }
        .frame(width: mapSize, height: mapSize)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 3))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .onAppear {
            updateCamera(for: location, heading: locationManager.heading, animated: false)
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let newLocation {
                updateCamera(for: newLocation, heading: locationManager.heading, animated: true)
            }
        }
        .onChange(of: locationManager.heading) { _, newHeading in
            updateCamera(for: location, heading: newHeading, animated: true)
        }
    }
    
    // MARK: - Location Indicator
    private var locationIndicator: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 80, height: 80)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(.white, lineWidth: 3))
        }
    }
    
    // MARK: - Placeholder View
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: mapSize, height: mapSize)
            
            placeholderContent
        }
    }
    
    @ViewBuilder
    private var placeholderContent: some View {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            VStack(spacing: 12) {
                Image(systemName: "location.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                
                Text("Enable Location")
                    .font(.headline)
                
                Button("Allow Access") {
                    locationManager.requestPermission()
                }
                .buttonStyle(.borderedProminent)
            }
            
        case .denied, .restricted:
            VStack(spacing: 12) {
                Image(systemName: "location.slash")
                    .font(.system(size: 50))
                    .foregroundStyle(.red)
                
                Text("Location Disabled")
                    .font(.headline)
                
                Text("Enable in Settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
        case .authorizedWhenInUse, .authorizedAlways:
            if locationManager.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Finding Location...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
        @unknown default:
            EmptyView()
        }
    }
    
    // MARK: - Helper Methods
    private func startLocationTracking() {
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdating()
        }
    }
    
    private func handleMapInteraction() {
        recenterTimer?.invalidate()
        recenterTimer = Timer.scheduledTimer(withTimeInterval: recenterDelay, repeats: false) { _ in
            if let location = locationManager.location {
                updateCamera(for: location, heading: locationManager.heading, animated: true)
            }
        }
    }
    
    private func updateCamera(for location: CLLocation, heading: CLHeading?, animated: Bool) {
        let mapHeading = calculateHeading(from: heading, location: location)
        let camera = MapCamera(
            centerCoordinate: location.coordinate,
            distance: zoomDistance,
            heading: mapHeading,
            pitch: cameraPitch
        )
        
        if animated {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .camera(camera)
            }
        } else {
            cameraPosition = .camera(camera)
        }
    }
    
    private func calculateHeading(from heading: CLHeading?, location: CLLocation) -> Double {
        if let heading, heading.headingAccuracy >= 0 {
            return heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        } else if location.course >= 0 {
            return location.course
        }
        return 0
    }
}

#Preview {
    CircularMapView()
        .padding()
}

