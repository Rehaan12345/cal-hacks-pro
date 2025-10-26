//
//  ProfileView.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/25/25.
//

import SwiftUI

struct ProfileView: View {
    
    @State private var capturedPhoto: UIImage?
    @State private var isProcessing = false
    @State private var userProfile: UserProfile?
    @State private var showProfileError = false
    @State private var profileErrorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(destination: SelfieCamera(capturedPhoto: $capturedPhoto, isProcessing: $isProcessing)) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.primary)
                        .bold()
                }
                
                // Processing Photo Indicator
                if isProcessing {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.primary)
                        Text("Processing your photo...")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Text("This is a sheet!")
                    .presentationDetents([.fraction(0.2),.fraction(0.5), .fraction(0.7)])
                    .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: capturedPhoto) { _, newPhoto in
            if let photo = newPhoto {
                Task {
                    await analyzePhoto(photo)
                }
            }
        }
        .alert("Profile Analysis Error", isPresented: $showProfileError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(profileErrorMessage)
        }
    }
    
    // MARK: - Photo Analysis
    private func analyzePhoto(_ photo: UIImage) async {
        print("Starting photo analysis...")
        
        do {
            let profile = try await GeminiService.shared.analyzePhoto(photo)
            
            await MainActor.run {
                self.userProfile = profile
                self.isProcessing = false
                print("Profile analysis complete:")
                print("Age: \(profile.age ?? "unknown")")
                print("Gender: \(profile.gender ?? "unknown")")
                print("Wealth indicators: \(profile.wealthIndicators)")
                print("Valuable items: \(profile.valuableItems)")
                print("Risk level: \(profile.riskLevel)")
                print("SF Symbol: \(profile.sfSymbolIcon)")
            }
        } catch {
            await MainActor.run {
                self.isProcessing = false
                self.profileErrorMessage = error.localizedDescription
                self.showProfileError = true
                print("Error analyzing photo: \(error.localizedDescription)")
            }
        }
    }
}
