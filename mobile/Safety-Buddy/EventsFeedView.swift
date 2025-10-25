//
//  EventsFeedView.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/24/25.
//

import SwiftUI

struct EventData: Identifiable {
    var id = UUID()
    var title: String
    var location: String
    var time: Date
    var severity: EventSeverity
    var source: String
    var userName: String
}

enum EventSeverity {
    case high
    case medium
    case low
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "info.circle.fill"
        }
    }
}

struct EventsFeedView: View {
    
    func timeAgo(from date: Date) -> String {
        let now = Date()
        let difference = now.timeIntervalSince(date)
        let hours = Int(difference / 3600)
        
        if hours == 0 {
            let minutes = Int(difference / 60)
            return minutes <= 1 ? "Just now" : "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            let days = hours / 24
            return "\(days)d ago"
        }
    }
    
    var events = [
        EventData(title: "Armed men at Cadillac Dr", location: "Cadillac Dr", time: Date().addingTimeInterval(-3600), severity: .high, source: "reddit", userName: "pushpinder"),
        EventData(title: "Traffic incident on Main Street", location: "Main Street", time: Date().addingTimeInterval(-7200), severity: .medium, source: "twitter", userName: "LocalNews"),
        EventData(title: "Suspicious activity reported", location: "Park Avenue", time: Date().addingTimeInterval(-10800), severity: .medium, source: "nextdoor", userName: "SafetyAlert"),
        EventData(title: "Package theft in the area", location: "Oak Street", time: Date().addingTimeInterval(-14400), severity: .low, source: "nextdoor", userName: "ResidentJoe"),
        EventData(title: "Car break-in reported", location: "Elm Street", time: Date().addingTimeInterval(-18000), severity: .medium, source: "reddit", userName: "LocalWatch"),
        EventData(title: "Loud noises heard at night", location: "Maple Ave", time: Date().addingTimeInterval(-21600), severity: .low, source: "nextdoor", userName: "ConcernedCitizen"),
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    eventRow(event: event)
                    
                    if index < events.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
            .background(.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .navigationTitle("Recent Events")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
    }
    
    func eventRow(event: EventData) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Severity indicator
            Circle()
                .fill(event.severity.color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: event.severity.icon)
                        .foregroundStyle(event.severity.color)
                        .font(.system(size: 16))
                )
            
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(event.location)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        
                        Text("\(event.source) • \(event.userName)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                 }
                 Spacer()
                 
            Text(timeAgo(from: event.time))
                     .font(.caption)
                     .foregroundStyle(.tertiary)
                 
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        EventsFeedView()
    }
}

