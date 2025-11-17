//
//  CameraViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import SwiftUI
import UIKit

protocol CameraViewModelDelegate: AnyObject {
}

final class CameraViewModel: ObservableObject {
    weak var delegate: CameraViewModelDelegate?
    var frontImage: UIImage?
    var backImage: UIImage?
    @Published var isUploading = false
    @Published var showCaptionView = false
    @Published var showGuideView: Bool = true
    @Published var showCompleteView: Bool = false
    
    // 스티커 제작뷰에서 활성화한 카메라인지 여부
    var isStickerCamera: Bool = false
    @Published var stickerKeyword: String? = nil
    
    // 카메라 컨트롤러 참조 (리셋을 위해 필요)
    weak var cameraController: CustomCameraViewController?
    
    /// 촬영 상태를 초기화하여 다시 전면 촬영부터 시작할 수 있도록 함
    func resetCameraState() {
        cameraController?.resetCameraState()
        frontImage = nil
        backImage = nil
        isUploading = false
        showCaptionView = false
        showGuideView = true
    }
}
