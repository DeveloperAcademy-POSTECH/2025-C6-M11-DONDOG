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
    
    let isStickerCamera: Bool
    
    @State private var captionViewModel: CaptionViewModel?
    @State private var shouldDismiss = false
    
    init(cameraViewModel: CameraViewModel, delegate: CaptionViewModelDelegate, isPresented: Binding<Bool>,  isStickerCamera: Bool) {
        _cameraViewModel = StateObject(wrappedValue: cameraViewModel)
        self.delegate = delegate
        self._isPresented = isPresented
        self.isStickerCamera = isStickerCamera
    }
    
    var body: some View {
        ZStack {
            CameraView(viewModel: cameraViewModel)
                .ignoresSafeArea()
            
            if cameraViewModel.showGuideView {
                if cameraViewModel.frontImage == nil {
                    ShootingGuideView(step: .front)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeOut(duration: 0.7)) {
                                    cameraViewModel.showGuideView = false
                                }
                            }
                        }
                } else {
                    ShootingGuideView(step: .back)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeOut(duration: 0.7)) {
                                    cameraViewModel.showGuideView = false
                                }
                            }
                        }
                }
            }
            
            if cameraViewModel.showCompleteView {
                ShootingCompleteView(isVisible: $cameraViewModel.showCompleteView) {
                    cameraViewModel.showCaptionView = true
                }
            }
            
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
        .customAlert(isPresented: $cameraViewModel.showExitAlert, title: "나가시겠어요?", message: "지금까지 찍은 사진은 저장되지 않아요", confirmTitle: "나가기", cancelTitle: "취소", onConfirm: {isPresented = false}, onCancel: {})
        .animation(.easeInOut(duration: 0.3), value: cameraViewModel.showGuideView)
        .onAppear {
            cameraViewModel.isStickerCamera = isStickerCamera
            cameraViewModel.showGuideView = true
        }
        .onChange(of: cameraViewModel.showCaptionView) { _, newValue in
            if newValue {
                cameraViewModel.cameraController?.stopSession()
                
                let newCaptionVM = CaptionViewModel(
                    frontImage: cameraViewModel.frontImage,
                    backImage: cameraViewModel.backImage
                )
                
                newCaptionVM.delegate = delegate
                
                captionViewModel = newCaptionVM
            } else {
                cameraViewModel.cameraController?.startSession()
            }
        }
        .onChange(of: shouldDismiss) { _, newValue in
            if newValue {
                isPresented = false
            }
        }
    }
}
