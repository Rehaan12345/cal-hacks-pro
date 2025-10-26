//
//  SafetyHeader.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 25/10/25.
//

import SwiftUI

struct SafetyHeader: View {
    @ObservedObject var metadata: LocationMetadata
    
    var body: some View {
        NavigationLink(destination: InfoView(metadata: metadata)) {
            HStack {
                Text(metadata.safetyState.rawValue)
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white)
                
                Image(systemName: "chevron.right")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .bold()
            }
        }
    }
}

struct BackgroundColor: View {
    @ObservedObject var metadata: LocationMetadata
    
    var body: some View {
        Rectangle()
            .foregroundStyle(
                (metadata.safetyState.backgroundColor).gradient
                )
            .ignoresSafeArea()
    }
}
