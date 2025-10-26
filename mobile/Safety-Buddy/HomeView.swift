//
//  HomeView.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/24/25.
//

import SwiftUI
internal import _LocationEssentials

enum SafetyState: String {
    case safe = "Safe"
    case danger = "Danger"
    case moderate = "Moderate"
}

extension SafetyState {
    var backgroundColor: Color {
        switch self {
        case .safe:
            return .green
        case .danger:
            return .red
        case .moderate:
            return .orange
        }
    }
}

struct HomeView: View {
    
    @State var currentState: SafetyState = .safe
    @StateObject private var locationManager = LocationManager()
    @State private var isSearchExpanded = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @Namespace private var searchAnimation
    
    @State private var safetyTipsAreExpanded = false
    
    @State private var metadata: LocationMetadata? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Group {
                    if locationManager.isAtActualLocation {
                        Text("\(Image(systemName: "location.fill")) Current Location")
                    } else if let neighborhoodName = locationManager.neighborhoodName {
                        Text("\(Image(systemName: "location.fill")) \(neighborhoodName)")
                    }
                }
                .bold()
                .foregroundStyle(.white)
                    
                if let metadata {
                    NavigationLink(destination: InfoView(metadata: metadata)) {
                        
                        HStack {
                            Text(currentState.rawValue)
                                .font(.system(size: 54, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Image(systemName: "chevron.right")
                                .font(.title)
                                .foregroundStyle(.secondary)
                                .bold()
                        }
                    }
                }
                
                Spacer()
                // Circular Map
                CircularMapView(locationManager: locationManager)
                    .minimumScaleFactor(0.5)
                
                Spacer()
                
                // Safety Tips Feed
                SafetyTipsFeed(isExpanded: $safetyTipsAreExpanded)
                
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 50)
            .background(
                currentState.backgroundColor.gradient
            )
            .onChange(of: metadata?.crimeRecsResponse == nil, { oldValue, newValue in
                dump(metadata?.crimeRecsResponse)
            })
            .onChange(of: locationManager.location, { oldValue, newValue in
                Task {
                    while(locationManager.neighborhoodName == nil) {
                        try await Task.sleep(nanoseconds: 20)
                    }
                    
                    metadata = LocationMetadata(latitude: newValue!.coordinate.latitude, longitude: newValue!.coordinate.longitude, neighborhood: locationManager.neighborhoodName!)
                }
            })
            .overlay(alignment: .bottom) {
                
                
                // Search Bar or Bottom Buttons
                HStack(spacing: 12) {
                    // Search Button/Bar (with integrated results when expanded)
                    VStack(spacing: 0) {
                        // Search Results (only when expanded and has results)
                        if isSearchExpanded && !locationManager.searchResults.isEmpty {
                            VStack(spacing: 0) {
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(locationManager.searchResults) { result in
                                            Button {
                                                locationManager.selectLocation(result)
                                                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                                    isSearchExpanded = false
                                                    searchText = ""
                                                    isSearchFocused = false
                                                }
                                            } label: {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.title)
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundStyle(.primary)
                                                        .lineLimit(1)
                                                    
                                                    if !result.subtitle.isEmpty {
                                                        Text(result.subtitle)
                                                            .font(.system(size: 13))
                                                            .foregroundStyle(.secondary)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 12)
                                            }
                                            .buttonStyle(.plain)
                                            
                                            if result.id != locationManager.searchResults.last?.id {
                                                Divider()
                                                    .padding(.leading, 20)
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                                .frame(height: 180)
                                
                                // Divider between results and search bar
                                Divider()
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottom)))
                        }
                        
                        // Search Input Bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .bold()
                                .frame(width: 60, height: 60)
                                .font(isSearchExpanded ? .title3 : .title2)
                                .foregroundStyle(.primary)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSearchFocused)
                                .matchedGeometryEffect(id: "searchIcon", in: searchAnimation)
                            
                            if isSearchExpanded {
                                TextField("Search location...", text: $searchText)
                                    .focused($isSearchFocused)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 17))
                                    .onChange(of: searchText) { _, newValue in
                                        locationManager.updateSearchQuery(newValue)
                                    }
                                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                                
                                if !searchText.isEmpty {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            searchText = ""
                                            locationManager.updateSearchQuery("")
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.gray.opacity(0.8))
                                            .font(.body)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                                
                                Button {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                        isSearchExpanded = false
                                        searchText = ""
                                        locationManager.updateSearchQuery("")
                                        isSearchFocused = false
                                    }
                                } label: {
                                    Text("Cancel")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 15)
                    }
                    .frame(maxWidth: isSearchExpanded ? .infinity : 60)
                    .frame(height: isSearchExpanded ? nil : 60)
                    .background(
                        Group {
                            if isSearchExpanded {
                                RoundedRectangle(cornerRadius: 30)
                                    .foregroundStyle(.clear)
                                    .glassEffect(.regular, in: .rect(cornerRadius: 30, style: .continuous))
                                    .matchedGeometryEffect(id: "searchBackground", in: searchAnimation)
                                    .glassEffectID("searchBackground", in: searchAnimation)
                            } else {
                                Circle()
                                    .foregroundStyle(.clear)
                                    .glassEffect(.regular, in: .circle)
                                    .glassEffectID("searchBackground", in: searchAnimation)
                                    .matchedGeometryEffect(id: "searchBackground", in: searchAnimation)
                            }
                        }
                    )
                    .onTapGesture {
                        if !isSearchExpanded {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                isSearchExpanded = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isSearchFocused = true
                            }
                        }
                    }
                    
                    if !isSearchExpanded {
                        Spacer()
                    
                        Menu {
                            Button {
                                SOSHandler().call911()
                            } label: {
                                Image(systemName: "car")
                                Text("Call Services")
                            }
                            Button {
                                SOSHandler().whistle()
                            } label: {
                                Image(systemName: "horn")
                                Text("Emergency Whistle")
                            }
                            Button {
                                SOSHandler().flash()
                            } label: {
                                Image(systemName: "flashlight.on.fill")
                                Text("Flash SOS")
                            }
                        } label: {
                            Image(systemName: "sos")
                                .foregroundStyle(.primary)
                                .bold()
                                .frame(width: 60, height: 60)
                                .glassEffect(.regular, in: .circle)
                        }
                        .tint(.primary)
                    }
                }
                .padding(.horizontal, isSearchFocused ? 20 : 40)
                .padding(.bottom, isSearchFocused ? 10 : 0)
                .animation(.spring, value: isSearchFocused)
            }
        }
        .animation(.spring, value: safetyTipsAreExpanded)
        
    }
}

#Preview {
    HomeView()
}
