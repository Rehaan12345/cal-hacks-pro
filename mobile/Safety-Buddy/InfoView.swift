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
    
    init(value: String, label: String, icon: String? = nil) {
        self.value = value
        self.label = label
        self.icon = icon
    }
}

// MARK: - Home View
struct InfoView: View {
    @Namespace private var namespace
    
    // MARK: - Data
    private let quotes = [
        SocialQuote(userName: "pushpinder", source: "reddit", quote: "Do not go there after sunset"),
        SocialQuote(userName: "LocalNews", source: "twitter", quote: "Avoid this area at night, seems sketchy"),
        SocialQuote(userName: "SafetyAlert", source: "nextdoor", quote: "I wouldn't walk alone here, just FYI"),
        SocialQuote(userName: "ResidentJoe", source: "reddit", quote: "Been living here 5 years, always lock your car"),
    ]
    
    private let stats = [
        StatCard(value: "4 in 100", label: "Crime Rate", icon: "exclamationmark.shield.fill"),
        StatCard(value: "Mugging", label: "Primary Risk", icon: "figure.walk"),
        StatCard(value: "Armed men at Cadillac Dr", label: "Recent Events"),
        StatCard(value: Date.now.formatted(date: .omitted, time: .shortened), label: "Get's safer at", icon: "clock.fill"),
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
            Text("92")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("Safety Score")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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
        }
        .padding(.horizontal)
    }
    
    private var socialFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What People Are Saying")
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
                    .foregroundStyle(.tint)
            }
            
            Spacer()
            
            Text(stat.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(stat.value)
//                .font(.system(size: 16, weight: .semibold, design: .rounded))
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
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("\(quote.source) • \(quote.userName)")
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


#Preview {
    InfoView()
}
