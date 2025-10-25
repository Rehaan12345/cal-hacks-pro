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
    
    @Binding var isExpanded: Bool
    
    // MARK: - Body
    var body: some View {
        // Single unified container with header inside
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                isExpanded.toggle()
            } label: {
                HStack {
                    if isExpanded {
                        Spacer()
                    }
                    
                    Text("\(Image(systemName: "sparkles")) Actionable Insights")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tint(.primary)
                    
                    if isExpanded {
                        Spacer()
                    }
                    
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .bold()
                    
                }
            }
            .padding(.bottom, isExpanded ? 8 : 0)
            
            if isExpanded {
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
                .frame(idealHeight: 120, maxHeight: 200)
                .padding(.bottom, -12)
                .clipped()
            }
        }
        .padding(12)
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20, style: .continuous))
        .animation(.spring, value: isExpanded)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Tip Row
    private func tipRow(_ tip: SafetyTip) -> some View {
        HStack(spacing: 10) {
//            Circle()
//                .fill(Color.blue.opacity(0.15))
//                .frame(width: 32, height: 32)
//                .overlay(
                    Image(systemName: tip.icon)
                        .foregroundStyle(.blue)
                        .font(.system(size: 20))
                        .frame(width: 32, height: 32)
//                )
            
            Text(tip.tip)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
//
//#Preview {
//    ZStack {
//        Color.green.opacity(0.3)
//            .ignoresSafeArea()
//        
//        VStack {
//            Spacer()
//            SafetyTipsFeed()
//            Spacer()
//        }
//    }
//}

