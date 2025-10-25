//
//  SOSHandler.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 25/10/25.
//

import Foundation
import AVFoundation

@MainActor
class SOSHandler {
    private var isFlashing = false
    
    func call911() {
        
    }
    
    func whistle() {
        
    }
    
    func flash() {
        guard !isFlashing else { return }
        
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
        
        isFlashing = true
        
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
        
        isFlashing = false
    }
    
    private func toggleTorch(_ device: AVCaptureDevice, on: Bool) async throws {
        try device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}
