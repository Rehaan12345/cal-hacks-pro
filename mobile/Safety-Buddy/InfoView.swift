//
//  InfoView.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/24/25.
//

import SwiftUI

// MARK: - Models
struct SocialQuote: Identifiable {
    let id = UUID()
    let userName: String
    let source: String
    let quote: String
}

struct StatCard: Identifiable {
    let id = UUID()
    let value: String
    let label: String
    let icon: String?
    let tint: Color
    
    init(value: String, label: String, icon: String? = nil, tint: Color) {
        self.value = value
        self.label = label
        self.icon = icon
        self.tint = tint
    }
}

// MARK: - Home View
struct InfoView: View {
    @Namespace private var namespace
    @ObservedObject var metadata: LocationMetadata
    
    // MARK: - Data
    private let quotes = [
        SocialQuote(userName: "pushpinder", source: "reddit", quote: "Do not go there after sunset"),
        SocialQuote(userName: "LocalNews", source: "twitter", quote: "Avoid this area at night, seems sketchy"),
        SocialQuote(userName: "SafetyAlert", source: "nextdoor", quote: "I wouldn't walk alone here, just FYI"),
        SocialQuote(userName: "ResidentJoe", source: "reddit", quote: "Been living here 5 years, always lock your car"),
    ]
    
    private let stats = [
        StatCard(value: "4 in 100", label: "Crime Rate", icon: "exclamationmark.shield.fill", tint: .pink),
        StatCard(value: "Mugging", label: "Primary Risk", icon: "figure.walk", tint: .orange),
        StatCard(value: "4 | last 12 hrs", label: "Recent Events", icon: "person.badge.shield.exclamationmark.fill", tint: .yellow),
        StatCard(value: Date.now.formatted(date: .omitted, time: .shortened), label: "Get's safer at", icon: "clock.fill", tint: .blue),
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    safetyScoreSection
                    statsGrid
                    socialFeed
                }
            }
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Sections
    private var safetyScoreSection: some View {
        VStack(spacing: 8) {
            if let rating = metadata.dangerScore {
                Text("\(rating)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            } else {
                ProgressView()
            }
            
            Text("Risk Level")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 40)
    }
    
    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(0..<2) { index in
                    statCardView(stats[index])
                }
            }
            
            HStack(spacing: 12) {
                // Recent Events - tappable
                NavigationLink {
                    EventsFeedView()
                        .navigationTransition(.zoom(sourceID: "recentEvents", in: namespace))
                } label: {
                    statCardView(stats[2])
                }
                .buttonStyle(.plain)
                .matchedTransitionSource(id: "recentEvents", in: namespace)
                
                statCardView(stats[3])
            }
            
            if let policeStations = metadata.policeStations {
                let value = String(format: "%.2f", policeStations.first?.distance ?? -1.00)
                statCardView(StatCard(value: value == "-1.00" ? "None nearby!" : "\(value) miles", label: "Nearest Police Station", icon: "car.fill", tint: .purple))
            }
        }
        .padding(.horizontal)
    }
    
    private var socialFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hear from locals:")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(Array(quotes.enumerated()), id: \.element.id) { index, quote in
                    quoteRowView(quote)
                    
                    if index < quotes.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
            .background(.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Card Views
    private func statCardView(_ stat: StatCard) -> some View {
        VStack(alignment: .leading) {
            if let icon = stat.icon {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundStyle(stat.tint)
            }
            
            Spacer()
            
            Text(stat.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(stat.value)
                .font(.title3)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .padding()
        .background(stat.tint.opacity(0.2).gradient)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(stat.tint.opacity(0.3), lineWidth: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private func quoteRowView(_ quote: SocialQuote) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(.systemFill))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconForSource(quote.source))
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text("\"\(quote.quote)\"")
                    .fontDesign(.serif)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("\(quote.userName) • \(quote.source.capitalized)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
    
    // MARK: - Helpers
    private func iconForSource(_ source: String) -> String {
        switch source.lowercased() {
        case "reddit": return "bubble.left.and.bubble.right.fill"
        case "twitter": return "bird.fill"
        case "nextdoor": return "house.fill"
        default: return "link"
        }
    }
}
