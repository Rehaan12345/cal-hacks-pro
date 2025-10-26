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
    case danger = "Dangerous"
    case moderate = "Moderate"
    case loading = "Loading..."
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
        case .loading:
            return .gray
        }
    }
}

struct HomeView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isSearchExpanded = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @Namespace private var searchAnimation
    
    @State private var safetyTipsAreExpanded = false

    

    @State private var metadata: LocationMetadata? = nil

    // Selfie camera states
    @State private var capturedPhoto: UIImage?
    @State private var isProcessing = false

    @State private var userProfile: UserProfile?
    @State private var showProfileError = false
    @State private var profileErrorMessage = ""


    @State private var showProfile = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Group {
                    if locationManager.isAtActualLocation {
                        Text("\(Image(systemName: "location.fill")) Current Location")
                    } else if !locationManager.neighborhoodName.isEmpty {
                        Text("\(Image(systemName: "location.fill")) \(locationManager.neighborhoodName)")
                    }
                }
                .bold()
                .foregroundStyle(.white)
                    
                if let metadata {
                    SafetyHeader(metadata: metadata)
                } else {
                    Text("Loading...")
                        .font(.title)
                        .bold()
                }
                
                Spacer()
                // Circular Map
                CircularMapView(locationManager: locationManager)
                    .minimumScaleFactor(0.5)
                
                Spacer()
                
                // Safety Tips Feed
                if let metadata {
                    SafetyTipsFeed(metadata: metadata, isExpanded: $safetyTipsAreExpanded)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 50)
            .background {
                if let metadata {
                    BackgroundColor(metadata: metadata)
                } else {
                    Color.gray
                        .ignoresSafeArea()
                }
            }
            .onChange(of: metadata?.crimeRecsResponse == nil, { oldValue, newValue in
                dump(metadata?.crimeRecsResponse)
            })
            .onChange(of: locationManager.neighborhoodName) { oldValue, newValue in
                Task {
                    while(locationManager.neighborhoodName.isEmpty) {
                        try await Task.sleep(nanoseconds: 20)
                    }
                    
                    if let location = locationManager.location {
                        
                        metadata = LocationMetadata(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, neighborhood: locationManager.neighborhoodName)
                    }
                }
            }
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
            .toolbar(content: {
                Button {
                    showProfile.toggle()
                } label: {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.primary)
                        .bold()
                }

            })
        }
        .animation(.spring, value: safetyTipsAreExpanded)
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
}

#Preview {
    HomeView()
}
