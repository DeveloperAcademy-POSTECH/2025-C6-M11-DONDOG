//
//  CameraViewContainer.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/9/25.
//

import SwiftUI

struct CameraViewContainer: View {
    @StateObject var cameraViewModel: CameraViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    @Binding var isPresented: Bool
    
    @State private var captionViewModel: CaptionViewModel?
    @State private var shouldDismiss = false
    
    init(cameraViewModel: CameraViewModel, feedViewModel: FeedViewModel, isPresented: Binding<Bool>) {
        _cameraViewModel = StateObject(wrappedValue: cameraViewModel)
        self.feedViewModel = feedViewModel
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            CameraView(viewModel: cameraViewModel)
                .ignoresSafeArea()
            
            if cameraViewModel.showCaptionView {
                if let captionVM = captionViewModel {
                    CaptionView(
                        viewModel: captionVM,
                        onCancel: {
                            cameraViewModel.resetCameraState()
                        },
                        onReturnToHome: {
                            isPresented = false
                        }
                    )
                }
            }
        }
        .onChange(of: cameraViewModel.showCaptionView) { _, _ in
            
            let newCaptionVM = CaptionViewModel(
                frontImage: cameraViewModel.frontImage,
                backImage: cameraViewModel.backImage
            )
            
            newCaptionVM.delegate = feedViewModel
            
            captionViewModel = newCaptionVM
        }
        .onChange(of: shouldDismiss) { _, newValue in
            if newValue {
                isPresented = false
            }
        }
    }
}
