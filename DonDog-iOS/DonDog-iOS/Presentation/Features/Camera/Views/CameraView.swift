//
//  CameraView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//
import Foundation
import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @StateObject var viewModel: CameraViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIViewController {
        let customCameraVC = CustomCameraViewController()
        customCameraVC.delegate = context.coordinator
        return customCameraVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 업데이트 로직이 필요한 경우 여기에 추가
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CustomCameraDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func didCaptureFrontImage(_ image: UIImage) {
            parent.viewModel.frontImage = image
        }
        
        func didCaptureBackImage(_ image: UIImage) {
            parent.viewModel.backImage = image
        }
        
        func didCompleteBothPhotos() {
            print("📸 촬영 완료 - Firebase 업로드 시작")
            
            if let frontImage = parent.viewModel.frontImage,
               let backImage = parent.viewModel.backImage {
                parent.viewModel.delegate?.didCaptureImages(
                    frontImage: frontImage, 
                    backImage: backImage
                )
                
                
                parent.viewModel.uploadImagesToFirebase()
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func didCancel() {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

