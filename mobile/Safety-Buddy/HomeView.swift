//
//  HomeView.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/24/25.
//

import SwiftUI

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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(currentState.rawValue)
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                    NavigationLink(destination: InfoView()) {
                        Image(systemName: "info.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                }
                
                Spacer()
                // Circular Map
                CircularMapView(locationManager: locationManager)
                
                Spacer()
                
                // Safety Tips Feed
                SafetyTipsFeed()

                
                Spacer()
                
                // Search Bar or Bottom Buttons
                HStack(spacing: 12) {
                    // Search Button/Bar
                    HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(isSearchExpanded ? .title3 : .title2)
                            .scaleEffect(isSearchFocused ? 1.1 : 1.0)
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
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, isSearchExpanded ? 20 : 18)
                    .padding(.vertical, isSearchExpanded ? 14 : 18)
                    .frame(maxWidth: isSearchExpanded ? .infinity : 60, maxHeight: 60)
                    .background(
                        ZStack {
                            // Base liquid glass layer
                            if isSearchExpanded {
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(.ultraThinMaterial)
                                    .matchedGeometryEffect(id: "searchBackground", in: searchAnimation)
                            } else {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .matchedGeometryEffect(id: "searchBackground", in: searchAnimation)
                            }
                            
                            // Shimmer gradient overlay
                            if isSearchExpanded {
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.3),
                                                .clear,
                                                .white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .opacity(0.6)
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.3),
                                                .clear,
                                                .white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .opacity(0.6)
                            }
                            
                            // Border highlight
                            if isSearchExpanded {
                                RoundedRectangle(cornerRadius: 28)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.5),
                                                .white.opacity(0.1),
                                                .clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            } else {
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.5),
                                                .white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            }
                        }
                    )
                    .shadow(color: .black.opacity(0.12), radius: isSearchExpanded ? 15 : 12, x: 0, y: isSearchExpanded ? 8 : 6)
                    .shadow(color: .blue.opacity(0.2), radius: isSearchExpanded ? 20 : 15, x: 0, y: isSearchExpanded ? 10 : 8)
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
                    
                        // SOS Button
                    Button {
                        print("SOS")
                    } label: {
                            ZStack {
                                // Liquid glass background
                                Circle()
                                    .fill(.ultraThinMaterial)
                                
                                // Shimmer overlay
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.3),
                                                .clear,
                                                .white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .opacity(0.6)
                                
                                // Border
                        Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.5),
                                                .white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                                
                                // Text
                                Text("SOS")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .frame(width: 60, height: 60)
                            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
                            .shadow(color: .blue.opacity(0.2), radius: 15, x: 0, y: 8)
                    }
                    .contextMenu {
                        Button {
                            print("call 911")
                        } label: {
                            Image(systemName: "car")
                            Text("Call Services")
                        }
                        Button {
                            print("whistle")
                        } label: {
                            Image(systemName: "horn")
                            Text("Emergency Whistle")
                        }
                        Button {
                            print("flash")
                        } label: {
                            Image(systemName: "flashlight.on.fill")
                            Text("Flash SOS")
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                
                // Search Results
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
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.title)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(.primary)
                                            
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 14)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if result.id != locationManager.searchResults.last?.id {
                                        Divider()
                                            .padding(.leading, 20)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 280)
                        .background(
                            ZStack {
                                // Liquid glass background
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial)
                                
                                // Shimmer overlay
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.25),
                                                .clear,
                                                .white.opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .opacity(0.5)
                                
                                // Border
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.4),
                                                .white.opacity(0.1),
                                                .clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            }
                        )
                        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
                        .shadow(color: .blue.opacity(0.15), radius: 18, x: 0, y: 8)
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        currentState.backgroundColor.opacity(0.8),
                        currentState.backgroundColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        
    }
}

#Preview {
    HomeView()
}
