//
//  CameraViewContainer.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/9/25.
//

import SwiftUI

struct CameraViewContainer: View {
    @StateObject var cameraViewModel: CameraViewModel
    var delegate: CaptionViewModelDelegate
    @Binding var isPresented: Bool
    
    @State private var captionViewModel: CaptionViewModel?
    @State private var shouldDismiss = false
    
    init(cameraViewModel: CameraViewModel, delegate: CaptionViewModelDelegate, isPresented: Binding<Bool>) {
        _cameraViewModel = StateObject(wrappedValue: cameraViewModel)
        self.delegate = delegate
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            CameraView(viewModel: cameraViewModel)
                .ignoresSafeArea()
            
            ZStack {
                Color.ppRealBlack
                    .opacity(0.7)
                    .ignoresSafeArea()
                
                Ellipse()
                    .frame(width: 300, height: 350)
                    .blendMode(.destinationOut)   // 이 부분을 구멍처럼 "빼버림"
            }
            .compositingGroup()
            
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
        .backHiddenSwipeEnabled()
        .onChange(of: cameraViewModel.showCaptionView) { _, _ in
            let newCaptionVM = CaptionViewModel(
                frontImage: cameraViewModel.frontImage,
                backImage: cameraViewModel.backImage
            )
            
            newCaptionVM.delegate = delegate
            
            captionViewModel = newCaptionVM
        }
        .onChange(of: shouldDismiss) { _, newValue in
            if newValue {
                isPresented = false
            }
        }
    }
}
