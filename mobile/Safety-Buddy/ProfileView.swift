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
    @State private var isCameraButtonPressed = false
    @StateObject private var deviceDetection = DeviceDetectionService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Processing Photo Indicator
                    if isProcessing {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(.primary)
                            Text("Analyzing your photo...")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: 20, style: .continuous))
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20, style: .continuous))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if let profile = userProfile {
                        // Profile Info Section
                        if profile.age != nil || profile.gender != nil {
                            profileInfoSection(profile)
                        }
                        
                        // Wealth Indicators Section
                        if !profile.wealthIndicators.isEmpty {
                            wealthIndicatorsSection(profile.wealthIndicators)
                        }
                        
                        // Valuable Items Section
                        if !profile.valuableItems.isEmpty {
                            valuableItemsSection(profile.valuableItems)
                        }
                        
                        // Risk Level Badge
                        riskLevelBadge(profile.riskLevel)
                    } else {
                        // Empty State
                        emptyStateView()
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .toolbar {
                NavigationLink(
                    destination: SelfieCamera(
                        capturedPhoto: $capturedPhoto,
                        isProcessing: $isProcessing
                    ),
                    isActive: $isCameraButtonPressed
                ) {
                    Image(systemName: "camera.fill")
                        .foregroundStyle(.primary)
                        .bold()
                }
            }
            .presentationDetents(isCameraButtonPressed ? [.large] : [.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadOrCreateProfile()
        }
        .onChange(of: capturedPhoto) { _, newPhoto in
            if let photo = newPhoto {
                Task {
                    await analyzePhoto(photo)
                }
            }
        }
        .onChange(of: deviceDetection.detectedDevices) { _, newDevices in
            updateProfileWithDetectedDevices(newDevices)
        }
        .alert("Profile Analysis Error", isPresented: $showProfileError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(profileErrorMessage)
        }
    }
    
    // MARK: - UI Components
    
    private func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.camera")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Profile Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Take a selfie to analyze your profile and valuable items")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
    
    private func profileInfoSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile Details")
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                if let age = profile.age {
                    infoTile(icon: "calendar", title: "Age", value: age, color: .blue)
                }
                
                if let gender = profile.gender {
                    infoTile(icon: "person.fill", title: "Gender", value: gender, color: .purple)
                }
            }
        }
    }
    
    private func infoTile(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
    }
    
    private func wealthIndicatorsSection(_ indicators: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
                
                Text("Wealth Indicators")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(indicators, id: \.self) { indicator in
                    indicatorChip(indicator)
                }
            }
        }
    }
    
    private func indicatorChip(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .clipShape(.rect(cornerRadius: 12, style: .continuous))
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12, style: .continuous))
    }
    
    private func valuableItemsSection(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                
                Text("Your Valuables")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(items.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(items, id: \.self) { item in
                    valuableTile(item)
                }
            }
        }
    }
    
    private func valuableTile(_ item: String) -> some View {
        let isAutoDetected = deviceDetection.detectedDevices.contains(item)
        
        return VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: itemIcon(for: item))
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                
                if isAutoDetected {
                    Text("✨")
                        .font(.caption2)
                }
            }
            
            Text(item)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(height: 100)
        .padding(12)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
    }
    
    private func riskLevelBadge(_ riskLevel: String) -> some View {
        let (color, icon) = riskLevelInfo(riskLevel)
        
        return HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
            
            Text("Risk Level:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(riskLevel.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .clipShape(.rect(cornerRadius: 12, style: .continuous))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12, style: .continuous))
    }
    
    private func riskLevelInfo(_ level: String) -> (Color, String) {
        switch level.lowercased() {
        case "low":
            return (.green, "checkmark.shield.fill")
        case "high":
            return (.red, "exclamationmark.shield.fill")
        default:
            return (.orange, "shield.fill")
        }
    }
    
    // MARK: - Profile Management
    
    private func loadOrCreateProfile() {
        if let savedProfile = UserProfile.load() {
            userProfile = savedProfile
            // Update with any new detected devices
            updateProfileWithDetectedDevices(deviceDetection.detectedDevices)
        } else {
            // Create new profile with detected devices
            var profile = UserProfile()
            profile.valuableItems = deviceDetection.detectedDevices
            profile.save()
            userProfile = profile
        }
    }
    
    private func updateProfileWithDetectedDevices(_ devices: [String]) {
        guard var profile = userProfile else { return }
        
        // Add detected devices that aren't already in the list
        for device in devices {
            if !profile.valuableItems.contains(device) {
                profile.valuableItems.insert(device, at: 0)
            }
        }
        
        profile.save()
        userProfile = profile
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
            var profile = try await GeminiService.shared.analyzePhoto(photo)
            
            await MainActor.run {
                // Prepend detected devices to the valuable items
                var allItems = deviceDetection.detectedDevices
                
                // Add photo-detected items that aren't already in detected devices
                for item in profile.valuableItems {
                    if !allItems.contains(item) {
                        allItems.append(item)
                    }
                }
                
                profile.valuableItems = allItems
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

// MARK: - FlowLayout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
