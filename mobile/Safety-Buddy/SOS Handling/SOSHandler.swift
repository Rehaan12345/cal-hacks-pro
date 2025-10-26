//
//  SOSHandler.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 25/10/25.
//

import Foundation
import UIKit

import AVFoundation
import MediaPlayer
import Combine

// Actor to keep audio players alive during playback
actor AudioPlayerManager {
    static let shared = AudioPlayerManager()
    private var players: [AVAudioPlayer] = []
    private var currentPlayer: AVAudioPlayer?
    
    func addPlayer(_ player: AVAudioPlayer) {
        players.append(player)
        currentPlayer = player
    }
    
    func removePlayer(_ player: AVAudioPlayer) {
        players.removeAll { $0 === player }
        if currentPlayer === player {
            currentPlayer = nil
        }
    }
    
    func getCurrentPlayer() -> AVAudioPlayer? {
        return currentPlayer
    }
    
    func clear() {
        players.removeAll()
        currentPlayer = nil
    }
}

@MainActor
class SOSHandler: ObservableObject {
    @Published var isWhistleActive = false
    @Published var isFlashActive = false
    @Published var whistleVolume: Float = 1.0
    @Published var flashBrightness: Float = 1.0
    
    private var flashTask: Task<Void, Never>?
    
    // Minimum brightness level (torch cannot be set to 0.0)
    static let minBrightness: Float = 0.05
    func call911() {
        if let url = URL(string: "tel://911") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        print("URL opened successfully")
                    } else {
                        print("Failed to open URL")
                    }
                }
            } else {
                print("Cannot open this URL")
            }
        }
    }
    
    func whistle() {
        isWhistleActive = true
        Task {
            await playWhistleSound()
        }
    }
    
    func flash() {
        isFlashActive = true
        flashTask = Task {
            await flashSOSPattern()
        }
    }
    
    func stopWhistle() {
        isWhistleActive = false
        Task {
            if let player = await AudioPlayerManager.shared.getCurrentPlayer() {
                player.stop()
                await AudioPlayerManager.shared.removePlayer(player)
            }
            
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false)
            } catch {
                print("Error deactivating audio session: \(error)")
            }
        }
    }
    
    func stopFlash() {
        isFlashActive = false
        flashTask?.cancel()
        flashTask = nil
        
        Task {
            guard let device = AVCaptureDevice.default(for: .video),
                  device.hasTorch else {
                return
            }
            
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            } catch {
                print("Error turning off torch: \(error)")
            }
        }
    }
    
    func adjustWhistleVolume(_ newVolume: Float) {
        whistleVolume = max(0.0, min(1.0, newVolume))
        Task {
            if let player = await AudioPlayerManager.shared.getCurrentPlayer() {
                player.volume = whistleVolume
            }
            setSystemVolume(to: whistleVolume)
        }
    }
    
    func adjustFlashBrightness(_ newBrightness: Float) {
        // Minimum brightness is 0.05 (5%) to avoid crash - torch level cannot be 0.0
        flashBrightness = max(0.05, min(1.0, newBrightness))
        
        Task {
            guard let device = AVCaptureDevice.default(for: .video),
                  device.hasTorch else {
                return
            }
            
            do {
                try device.lockForConfiguration()
                if device.torchMode == .on {
                    try device.setTorchModeOn(level: flashBrightness)
                }
                device.unlockForConfiguration()
            } catch {
                print("Error adjusting torch brightness: \(error)")
            }
        }
    }
    
    private func flashSOSPattern() async {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            print("Torch not available")
            await MainActor.run {
                isFlashActive = false
            }
            return
        }
        
        // SOS Pattern: ··· ––– ···
        // Dot: 0.2s on, Dash: 0.6s on
        // Gap between signals: 0.2s
        // Gap between letters: 0.6s
        
        let dotDuration: UInt64 = 200_000_000  // 0.2 seconds in nanoseconds
        let dashDuration: UInt64 = 600_000_000 // 0.6 seconds in nanoseconds
        let shortGap: UInt64 = 200_000_000     // 0.2 seconds
        let letterGap: UInt64 = 600_000_000    // 0.6 seconds
        
        do {
            // Flash SOS pattern continuously until stopped
            while !Task.isCancelled {
                // S (···)
                for i in 0..<3 {
                    guard !Task.isCancelled else { break }
                    try await toggleTorch(device, on: true, brightness: await flashBrightness)
                    try await Task.sleep(nanoseconds: dotDuration)
                    try await toggleTorch(device, on: false, brightness: 1.0)
                    if i < 2 {
                        try await Task.sleep(nanoseconds: shortGap)
                    }
                }
                
                guard !Task.isCancelled else { break }
                try await Task.sleep(nanoseconds: letterGap)
                
                // O (–––)
                for i in 0..<3 {
                    guard !Task.isCancelled else { break }
                    try await toggleTorch(device, on: true, brightness: await flashBrightness)
                    try await Task.sleep(nanoseconds: dashDuration)
                    try await toggleTorch(device, on: false, brightness: 1.0)
                    if i < 2 {
                        try await Task.sleep(nanoseconds: shortGap)
                    }
                }
                
                guard !Task.isCancelled else { break }
                try await Task.sleep(nanoseconds: letterGap)
                
                // S (···)
                for i in 0..<3 {
                    guard !Task.isCancelled else { break }
                    try await toggleTorch(device, on: true, brightness: await flashBrightness)
                    try await Task.sleep(nanoseconds: dotDuration)
                    try await toggleTorch(device, on: false, brightness: 1.0)
                    if i < 2 {
                        try await Task.sleep(nanoseconds: shortGap)
                    }
                }
                
                guard !Task.isCancelled else { break }
                // Pause between SOS repetitions
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
            
            // Ensure torch is off when done
            try await toggleTorch(device, on: false, brightness: 1.0)
        } catch {
            if !Task.isCancelled {
                print("Error flashing SOS: \(error)")
            }
        }
        
        await MainActor.run {
            isFlashActive = false
        }
    }
    
    private func toggleTorch(_ device: AVCaptureDevice, on: Bool, brightness: Float) async throws {
        try device.lockForConfiguration()
        if on {
            // Ensure brightness is at least 0.05 (5%) - torch level cannot be 0.0
            let safeBrightness = max(0.05, min(1.0, brightness))
            try device.setTorchModeOn(level: safeBrightness)
        } else {
            device.torchMode = .off
        }
        device.unlockForConfiguration()
    }
    
    private func playWhistleSound() async {
        do {
            // Set system volume to current whistle volume
            let currentVolume = await whistleVolume
            setSystemVolume(to: currentVolume)
            
            // Configure audio session for maximum volume output
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
            
            // Load siren-ultra.mp3 from bundle
            guard let sirenURL = Bundle.main.url(forResource: "siren-ultra", withExtension: "mp3") else {
                print("Could not find siren-ultra.mp3")
                await MainActor.run {
                    isWhistleActive = false
                }
                return
            }
            
            // Create audio player with settings
            let player = try AVAudioPlayer(contentsOf: sirenURL)
            player.volume = currentVolume
            player.numberOfLoops = -1 // Loop indefinitely
            player.enableRate = true
            player.rate = 1.0 // Normal playback speed
            player.prepareToPlay()
            
            // Keep player alive during playback
            await AudioPlayerManager.shared.addPlayer(player)
            
            player.play()
            
            // Keep playing until stopped manually
            while await isWhistleActive {
                try await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1 seconds
            }
            
            // Stop and cleanup
            player.stop()
            await AudioPlayerManager.shared.removePlayer(player)
            
            try audioSession.setActive(false)
        } catch {
            print("Error playing siren: \(error)")
            await MainActor.run {
                isWhistleActive = false
            }
        }
    }
    
    private func setSystemVolume(to level: Float) {
        // Use MPVolumeView to access the system volume slider
        let volumeView = MPVolumeView()
        
        // Find the volume slider
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            // Dispatch to main thread for UI update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                slider.value = level
            }
        }
    }
}
