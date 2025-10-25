//
//  SOSHandler.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 25/10/25.
//

import Foundation
import AVFoundation
import MediaPlayer

// Actor to keep audio players alive during playback
actor AudioPlayerManager {
    static let shared = AudioPlayerManager()
    private var players: [AVAudioPlayer] = []
    
    func addPlayer(_ player: AVAudioPlayer) {
        players.append(player)
    }
    
    func removePlayer(_ player: AVAudioPlayer) {
        players.removeAll { $0 === player }
    }
    
    func clear() {
        players.removeAll()
    }
}

struct SOSHandler {
    func call911() {
        
    }
    
    func whistle() {
        Task {
            await playWhistleSound()
        }
    }
    
    func flash() {
        Task {
            await flashSOSPattern()
        }
    }
    
    private func flashSOSPattern() async {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            print("Torch not available")
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
            // Flash SOS pattern 3 times
            for _ in 0..<3 {
                // S (···)
                for i in 0..<3 {
                    try await toggleTorch(device, on: true)
                    try await Task.sleep(nanoseconds: dotDuration)
                    try await toggleTorch(device, on: false)
                    if i < 2 {
                        try await Task.sleep(nanoseconds: shortGap)
                    }
                }
                
                try await Task.sleep(nanoseconds: letterGap)
                
                // O (–––)
                for i in 0..<3 {
                    try await toggleTorch(device, on: true)
                    try await Task.sleep(nanoseconds: dashDuration)
                    try await toggleTorch(device, on: false)
                    if i < 2 {
                        try await Task.sleep(nanoseconds: shortGap)
                    }
                }
                
                try await Task.sleep(nanoseconds: letterGap)
                
                // S (···)
                for i in 0..<3 {
                    try await toggleTorch(device, on: true)
                    try await Task.sleep(nanoseconds: dotDuration)
                    try await toggleTorch(device, on: false)
                    if i < 2 {
                        try await Task.sleep(nanoseconds: shortGap)
                    }
                }
                
                // Pause between SOS repetitions
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
        } catch {
            print("Error flashing SOS: \(error)")
        }
    }
    
    private func toggleTorch(_ device: AVCaptureDevice, on: Bool) async throws {
        try device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
    
    private func playWhistleSound() async {
        do {
            // Set system volume to maximum
            setSystemVolume(to: 1.0)
            
            // Configure audio session for maximum volume output
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
            
            // Load siren-ultra.mp3 from bundle
            guard let sirenURL = Bundle.main.url(forResource: "siren-ultra", withExtension: "mp3") else {
                print("Could not find siren-ultra.mp3")
                return
            }
            
            // Create audio player with maximum settings
            let player = try AVAudioPlayer(contentsOf: sirenURL)
            player.volume = 1.0 // Max player volume
            player.numberOfLoops = -1 // Loop indefinitely
            player.enableRate = true
            player.rate = 1.0 // Normal playback speed
            player.prepareToPlay()
            
            // Keep player alive during playback
            await AudioPlayerManager.shared.addPlayer(player)
            
            player.play()
            
            // Play for 10 seconds
            try await Task.sleep(nanoseconds: 10_000_000_000)
            
            // Stop and cleanup
            player.stop()
            await AudioPlayerManager.shared.removePlayer(player)
            
            try audioSession.setActive(false)
        } catch {
            print("Error playing siren: \(error)")
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
