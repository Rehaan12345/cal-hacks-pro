//
//  SelfieCamera.swift
//  Safety-Buddy
//
//  Created by Pushpinder on 10/25/25.
//
import UIKit
import SwiftUI

struct SelfieCamera: View {
    @Binding var capturedPhoto: UIImage?
    @Binding var isProcessing: Bool
    
    var body: some View {
        ZStack {
            // Camera view
            CameraViewRepresentable(capturedPhoto: $capturedPhoto, isProcessing: $isProcessing)
                .ignoresSafeArea()
            
            // Instruction overlay
            VStack {
                Text("Make sure you capture all the valuables")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(.black.opacity(0.7))
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .padding(.top, 60)
                
                Spacer()
            }
        }
    }
}

struct CameraViewRepresentable: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var capturedPhoto: UIImage?
    @Binding var isProcessing: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front  // This sets it to selfie camera
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraViewRepresentable
        
        init(_ parent: CameraViewRepresentable) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Handle the captured image here
            if let image = info[.originalImage] as? UIImage {
                // Save or process your selfie image
                let flippedImage = image.withHorizontallyFlippedOrientation()
                
                // Set the captured photo and start processing
                parent.capturedPhoto = flippedImage
                parent.isProcessing = true
                
                print("Selfie captured!")
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
