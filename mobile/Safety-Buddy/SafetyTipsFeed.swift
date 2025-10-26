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
    @ObservedObject var metadata: LocationMetadata
    
    @Binding var isExpanded: Bool
    
    var recommendationsHaveLoaded: Bool {
        metadata.crimeRecsResponse != nil
    }
    
    // MARK: - Body
    var body: some View {
        // Single unified container with header inside
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                if recommendationsHaveLoaded {
                    isExpanded.toggle()
                }
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
                    
                    if recommendationsHaveLoaded {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .bold()
                    } else {
                        ProgressView()
                    }
                    
                }
            }
            .padding(.bottom, isExpanded ? 8 : 0)
            
            if isExpanded {
                // Scrollable tips list
                ScrollView {
                    VStack(spacing: 0) {
                        if let tips = metadata.crimeRecsResponse {
                            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                                tipRow(tip)
                                
                                if index < tips.count - 1 {
                                    Divider()
                                        .padding(.leading, 42)
                                }
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
        .onChange(of: recommendationsHaveLoaded) {
            isExpanded = recommendationsHaveLoaded
        }
    }
    
    // MARK: - Tip Row
    private func tipRow(_ tip: String) -> some View {
        HStack(spacing: 10) {
//            Circle()
//                .fill(Color.blue.opacity(0.15))
//                .frame(width: 32, height: 32)
//                .overlay(
                    Image(systemName: "star.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 20))
                        .frame(width: 32, height: 32)
//                )
            
            Text(tip)
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

