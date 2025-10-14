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
                            // 업로드 완료 시 기존 로직 실행
                            feedViewModel.didUploadPost()
                            
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
        .onChange(of: cameraViewModel.showCaptionView) { newValue in
            if newValue {
                let newCaptionVM = CaptionViewModel(
                    frontImage: cameraViewModel.frontImage,
                    backImage: cameraViewModel.backImage
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
    
}

