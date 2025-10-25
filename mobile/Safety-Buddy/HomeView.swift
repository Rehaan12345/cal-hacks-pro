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
                    .minimumScaleFactor(0.5)
                
                Spacer()
                
                // Safety Tips Feed
                SafetyTipsFeed()
                
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
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
//                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSearchFocused)
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
                        GlassEffectContainer {
                            if isSearchExpanded {
                                RoundedRectangle(cornerRadius: 30)
                                    .glassEffect(.regular, in: .rect(cornerRadius: 30, style: .continuous))
//                                    .matchedGeometryEffect(id: "searchBackground", in: searchAnimation)
                                    .glassEffectID("searchBackground", in: searchAnimation)
                            } else {
                                Circle()
                                    .glassEffect(.regular, in: .circle)
                                    .glassEffectID("searchBackground", in: searchAnimation)
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
                        
                        // SOS Button
                        Button {
                            print("SOS")
                        } label: {
                            Image(systemName: "sos")
                                .foregroundStyle(.black)
                                .bold()
                                .frame(width: 60, height: 60)
                                .glassEffect(.regular, in: .circle)
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
                .padding(.horizontal, isSearchFocused ? 20 : 40)
                .padding(.bottom, isSearchFocused ? 50 : 0)
                .animation(.spring, value: isSearchFocused)
            }
        }
        
    }
}

#Preview {
    HomeView()
}
