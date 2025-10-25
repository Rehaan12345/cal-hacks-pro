//
//  SafetyTipsFeed.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/24/25.
//

import SwiftUI

// MARK: - Model
struct SafetyTip: Identifiable {
    let id = UUID()
    let icon: String
    let tip: String
    let category: String
}

// MARK: - Safety Tips Feed
struct SafetyTipsFeed: View {
    // MARK: - Data
    private let tips = [
        SafetyTip(icon: "eye.fill", tip: "Stay aware of your surroundings", category: "Awareness"),
        SafetyTip(icon: "moon.stars.fill", tip: "Avoid walking alone after dark", category: "Night Safety"),
        SafetyTip(icon: "figure.walk", tip: "Stick to well-lit, populated areas", category: "Navigation"),
        SafetyTip(icon: "lock.fill", tip: "Keep your car doors locked", category: "Vehicle"),
        SafetyTip(icon: "person.2.fill", tip: "Travel in groups when possible", category: "Social"),
        SafetyTip(icon: "bell.fill", tip: "Trust your instincts", category: "Awareness"),
    ]
    
    // MARK: - Body
    var body: some View {
        // Single unified container with header inside
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                
                Text("Safety Tips")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Scrollable tips list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                        tipRow(tip)
                        
                        if index < tips.count - 1 {
                            Divider()
                                .padding(.leading, 42)
                        }
                    }
                }
            }
            .frame(height: 120)
            .padding(.bottom, -12)
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 20, style: .continuous))
        .frame(maxWidth: 280)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Tip Row
    private func tipRow(_ tip: SafetyTip) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: tip.icon)
                        .foregroundStyle(.blue)
                        .font(.system(size: 14))
                )
            
            Text(tip.tip)
                .font(.caption)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        Color.green.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            SafetyTipsFeed()
            Spacer()
        }
    }
}

