//
//  SOSHandler.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 25/10/25.
//

import Foundation
import AVFoundation

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
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            // Create audio data for whistle
            let sampleRate = 44100
            let duration = 0.6 // seconds
            let frequency = 2500.0 // Hz
            
            let numberOfSamples = Int(Double(sampleRate) * duration)
            var audioData = Data(capacity: numberOfSamples * MemoryLayout<Int16>.size)
            
            // Generate whistle sound as 16-bit PCM
            for i in 0..<numberOfSamples {
                let sample = sin(2.0 * Double.pi * frequency * Double(i) / Double(sampleRate))
                
                // Apply envelope
                let envelope: Double
                let fadeLength = numberOfSamples / 10
                if i < fadeLength {
                    envelope = Double(i) / Double(fadeLength)
                } else if i > numberOfSamples - fadeLength {
                    envelope = Double(numberOfSamples - i) / Double(fadeLength)
                } else {
                    envelope = 1.0
                }
                
                let int16Sample = Int16(sample * envelope * Double(Int16.max))
                withUnsafeBytes(of: int16Sample) { audioData.append(contentsOf: $0) }
            }
            
            // Create WAV file in memory
            var wavData = Data()
            
            // WAV header
            wavData.append("RIFF".data(using: .ascii)!)
            let fileSize = UInt32(36 + audioData.count)
            withUnsafeBytes(of: fileSize.littleEndian) { wavData.append(contentsOf: $0) }
            wavData.append("WAVE".data(using: .ascii)!)
            
            // Format chunk
            wavData.append("fmt ".data(using: .ascii)!)
            withUnsafeBytes(of: UInt32(16).littleEndian) { wavData.append(contentsOf: $0) } // Chunk size
            withUnsafeBytes(of: UInt16(1).littleEndian) { wavData.append(contentsOf: $0) } // PCM
            withUnsafeBytes(of: UInt16(1).littleEndian) { wavData.append(contentsOf: $0) } // Mono
            withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { wavData.append(contentsOf: $0) }
            withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { wavData.append(contentsOf: $0) } // Byte rate
            withUnsafeBytes(of: UInt16(2).littleEndian) { wavData.append(contentsOf: $0) } // Block align
            withUnsafeBytes(of: UInt16(16).littleEndian) { wavData.append(contentsOf: $0) } // Bits per sample
            
            // Data chunk
            wavData.append("data".data(using: .ascii)!)
            withUnsafeBytes(of: UInt32(audioData.count).littleEndian) { wavData.append(contentsOf: $0) }
            wavData.append(audioData)
            
            // Play whistle 3 times
            for _ in 0..<3 {
                let player = try AVAudioPlayer(data: wavData)
                player.volume = 1.0
                player.prepareToPlay()
                
                // Keep player alive during playback
                await AudioPlayerManager.shared.addPlayer(player)
                
                player.play()
                
                // Wait for playback duration (0.6 seconds for the whistle)
                try await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds
                
                // Remove player after playback
                await AudioPlayerManager.shared.removePlayer(player)
            }
            
            try audioSession.setActive(false)
        } catch {
            print("Error playing whistle: \(error)")
        }
    }
}
