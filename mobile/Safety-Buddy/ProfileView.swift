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
    @State private var userProfile: UserProfile? = UserProfile.load() ?? {
        // Mock data if no saved profile exists
        var profile = UserProfile()
        profile.valuableItems = [
            "iPhone 15 Pro",
            "Apple Watch Ultra",
            "AirPods Pro",
            "Designer Wallet",
            "MacBook Pro",
            "Ray-Ban Sunglasses"
        ]
        profile.age = "25-30"
        profile.gender = "Male"
        profile.wealthIndicators = ["Premium tech devices", "Designer accessories"]
        profile.riskLevel = "medium"
        profile.save() // Save the mock data
        return profile
    }()
    @State private var showProfileError = false
    @State private var profileErrorMessage = ""
    @State private var isCameraButtonPressed = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
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
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Valuables List
                if let profile = userProfile, !profile.valuableItems.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack {
                            Text("\(Image(systemName: "sparkles")) Your Valuables")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("\(profile.valuableItems.count) items")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.bottom, 8)
                        
                        // List of valuables
                        VStack(spacing: 0) {
                            ForEach(Array(profile.valuableItems.enumerated()), id: \.offset) { index, item in
                                valuableRow(item)
                                
                                if index < profile.valuableItems.count - 1 {
                                    Divider()
                                        .padding(.leading, 42)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .clipShape(.rect(cornerRadius: 20, style: .continuous))
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20, style: .continuous))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .toolbar {
                NavigationLink(
                    destination: SelfieCamera(
                        capturedPhoto: $capturedPhoto,
                        isProcessing: $isProcessing
                    ),
                    isActive: $isCameraButtonPressed
                ) {
                    Image(systemName: "camera")
                        .foregroundStyle(.primary)
                        .bold()
                }
            }
            .presentationDetents(isCameraButtonPressed ? [.large] : [.fraction(0.5), .fraction(0.7)])
            .presentationDragIndicator(.visible)
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
    
    // MARK: - Valuable Row
    private func valuableRow(_ item: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: itemIcon(for: item))
                .foregroundStyle(.blue)
                .font(.system(size: 20))
                .frame(width: 32, height: 32)
            
            Text(item)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    private func itemIcon(for item: String) -> String {
        let lowercased = item.lowercased()
        
        if lowercased.contains("watch") || lowercased.contains("apple watch") {
            return "applewatch"
        } else if lowercased.contains("phone") || lowercased.contains("iphone") {
            return "iphone"
        } else if lowercased.contains("laptop") || lowercased.contains("macbook") || lowercased.contains("computer") {
            return "laptopcomputer"
        } else if lowercased.contains("airpods") || lowercased.contains("earbuds") || lowercased.contains("headphones") {
            return "airpodspro"
        } else if lowercased.contains("wallet") || lowercased.contains("purse") {
            return "creditcard.fill"
        } else if lowercased.contains("jewelry") || lowercased.contains("ring") || lowercased.contains("necklace") {
            return "sparkles"
        } else if lowercased.contains("bag") || lowercased.contains("backpack") {
            return "bag.fill"
        } else if lowercased.contains("glasses") || lowercased.contains("sunglasses") {
            return "eyeglasses"
        } else if lowercased.contains("key") {
            return "key.fill"
        } else if lowercased.contains("camera") {
            return "camera.fill"
        } else {
            return "tag.fill"
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
                
                // Save the profile to UserDefaults
                profile.save()
                
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
