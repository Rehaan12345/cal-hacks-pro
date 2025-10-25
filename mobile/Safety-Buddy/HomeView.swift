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
                CircularMapView()
                
                Spacer()
                
                // Safety Tips Feed
                SafetyTipsFeed()

                
                Spacer()
                
                // Bottom Buttons
                HStack {
                    Button {
                        print("Search")
                    } label: {
                        Circle()
                            .fill(.ultraThickMaterial)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "magnifyingglass")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    
                    Spacer()
                    
                    Button {
                        print("SOS")
                    } label: {
                        Circle()
                            .fill(.ultraThickMaterial)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text("SOS")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.blue)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
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
