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
                    CaptionView(viewModel: captionVM) {
                        withAnimation {
                            shouldDismiss = true
                        }
                    }
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .onChange(of: cameraViewModel.showCaptionView) { newValue in
            if newValue {
                let newCaptionVM = CaptionViewModel(
                    frontImage: cameraViewModel.frontImage,
                    backImage: cameraViewModel.backImage
                )
                
                newCaptionVM.delegate = ContainerDelegate(
                    onUploadComplete: { [self] in
                        handleUploadComplete()
                    }
                )
                
                captionViewModel = newCaptionVM
            }
        }
        .onChange(of: shouldDismiss) { newValue in
            if newValue {
                isPresented = false
            }
        }
    }
    
    private func handleUploadComplete() {
        
        feedViewModel.didUploadPost()
        
        cameraViewModel.frontImage = nil
        cameraViewModel.backImage = nil
        cameraViewModel.showCaptionView = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shouldDismiss = true
        }
    }
    
    class ContainerDelegate: CaptionViewModelDelegate {
        let onUploadComplete: () -> Void
        
        init(onUploadComplete: @escaping () -> Void) {
            self.onUploadComplete = onUploadComplete
        }
        
        func didUploadPost() {
            onUploadComplete()
        }
    }
}

