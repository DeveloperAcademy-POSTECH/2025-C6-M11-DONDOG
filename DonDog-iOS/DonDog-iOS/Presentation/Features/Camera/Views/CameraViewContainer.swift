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
                            // xmark 버튼 클릭 시 촬영 상태를 초기화하여 다시 전면 촬영부터 시작
                            cameraViewModel.resetCameraState()
                        },
                        onUploadComplete: {
                            // ✅ 업로드 시작 시 상태 설정
                            feedViewModel.isUploading = true
                            
                            // CameraViewModel 상태 초기화
                            cameraViewModel.frontImage = nil
                            cameraViewModel.backImage = nil
                            
                            // 화면 닫기
                            isPresented = false
                        }
                    )
                }
            }
        }
        .onChange(of: cameraViewModel.showCaptionView) { oldValue, newValue in
            
            let newCaptionVM = CaptionViewModel(
                frontImage: cameraViewModel.frontImage,
                backImage: cameraViewModel.backImage
            )
            
            // ✅✅✅ 중요: delegate 설정!
            newCaptionVM.delegate = feedViewModel
            
            captionViewModel = newCaptionVM
        }
        .onChange(of: shouldDismiss) { oldValue, newValue in
            if newValue {
                isPresented = false
            }
        }
    }
    
}

