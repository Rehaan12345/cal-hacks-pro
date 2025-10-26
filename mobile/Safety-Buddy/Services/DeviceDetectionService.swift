//
//  DeviceDetectionService.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/25/25.
//

import UIKit
import WatchConnectivity
import Combine

class DeviceDetectionService: NSObject, ObservableObject {
    static let shared = DeviceDetectionService()
    
    @Published var detectedDevices: [String] = []
    
    private override init() {
        super.init()
        detectDevices()
        setupWatchConnectivity()
    }
    
    // MARK: - Device Detection
    
    func detectDevices() {
        var devices: [String] = []
        
        // Detect current iPhone/iPad model
        if let currentDevice = getCurrentDeviceModel() {
            devices.append(currentDevice)
        }
        
        self.detectedDevices = devices
        print("📱 Detected devices: \(devices)")
    }
    
    // MARK: - Current Device Model
    
    private func getCurrentDeviceModel() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return mapToDeviceName(identifier: identifier)
    }
    
    private func mapToDeviceName(identifier: String) -> String? {
        switch identifier {
        // iPhone 16 series
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        
        // iPhone 15 series
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        
        // iPhone 14 series
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        
        // iPhone 13 series
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        
        // iPhone 12 series
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        
        // iPhone 11 series
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        
        // iPhone XR, XS, XS Max
        case "iPhone11,8": return "iPhone XR"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,6", "iPhone11,4": return "iPhone XS Max"
        
        // iPhone X
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        
        // iPhone SE
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone12,8": return "iPhone SE (2nd generation)"
        
        // iPad Pro
        case "iPad14,3", "iPad14,4": return "iPad Pro 11-inch (4th generation)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9-inch (6th generation)"
        case "iPad13,18", "iPad13,19": return "iPad Pro 12.9-inch (5th generation)"
        
        // iPad Air
        case "iPad14,8", "iPad14,9": return "iPad Air (5th generation)"
        case "iPad13,16", "iPad13,17": return "iPad Air (4th generation)"
        
        // iPad mini
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        
        // iPad
        case "iPad13,1", "iPad13,2": return "iPad (10th generation)"
        
        // Simulator
        case "i386", "x86_64", "arm64":
            if let simulatorModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
                return mapToDeviceName(identifier: simulatorModel)
            }
            return "iPhone Simulator"
        
        default:
            return "iPhone"
        }
    }
    
    // MARK: - Apple Watch Detection
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("⌚️ Watch connectivity not supported")
            return
        }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
}

// MARK: - WCSessionDelegate

extension DeviceDetectionService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ Watch session activation error: \(error.localizedDescription)")
            return
        }
        
        DispatchQueue.main.async {
            if session.isPaired {
                print("⌚️ Apple Watch is paired")
                
                // Add Apple Watch to detected devices
                if !self.detectedDevices.contains(where: { $0.contains("Apple Watch") }) {
                    if session.isWatchAppInstalled {
                        self.detectedDevices.append("Apple Watch")
                    } else {
                        self.detectedDevices.append("Apple Watch")
                    }
                }
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⌚️ Watch session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("⌚️ Watch session deactivated")
        WCSession.default.activate()
    }
}

