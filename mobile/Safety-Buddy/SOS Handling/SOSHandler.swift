//
//  SOSHandler.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 25/10/25.
//

import Foundation
import UIKit

struct SOSHandler {
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
        
    }
    
    func flash() {
        
    }
}
