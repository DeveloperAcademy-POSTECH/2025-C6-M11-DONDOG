//
//  CameraViewController.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/4/25.
//

import AVFoundation
import SwiftUI
import UIKit

protocol CustomCameraDelegate: AnyObject {
    func didCaptureFrontImage(_ image: UIImage)
    func didCaptureBackImage(_ image: UIImage)
    func didCancel()
    func didCompleteBothPhotos()
}

class CustomCameraViewController: UIViewController, UIGestureRecognizerDelegate {
    // MARK: - Properties
    weak var delegate: CustomCameraDelegate?
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var photoOutput: AVCapturePhotoOutput!
    var currentCamera: AVCaptureDevice?
    weak var viewModel: CameraViewModel?
    
    var isStickerCamera: Bool = false
    let stickerMaskView = UIView()
    let stickerMaskLayer = CAShapeLayer()
    var stickerKeyword: String?
    var onStickerCreated: ((UIImage) -> Void)?
    let stickerGuideContainer = UIStackView()
    let stickerTitleLabel = UILabel()
    let stickerSubtitleLabel = UILabel()
    
    var isCapturingFront = true
    var frontImage: UIImage?
    var backImage: UIImage?
    var isCaptureButtonEnabled = true
    let previewContainerView = UIView()
    let capturedImageView = UIImageView()
    let captureButton = UIButton()
    let captureButtonInnerCircle = UIView()
    let cancelButton = UIButton()
    
    let stepIndicatorContainer = UIView()
    let step1Circle = UIView()
    let step1Label = UILabel()
    let step1TextLabel = UILabel()
    let step1PulseView = UIView()
    let stepDotsContainer = UIView()
    let step2Circle = UIView()
    let step2Label = UILabel()
    let step2TextLabel = UILabel()
    let step2PulseView = UIView()
    let step1CheckmarkImageView = UIImageView()
    let step2CheckmarkImageView = UIImageView()
    
    let bottomButtonContainer = UIView()
    let retakeButton = UIButton()
    let nextButton = UIButton()
    
    var isFrontPhotoConfirmed = false
    var isBackPhotoConfirmed = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureModeFromEmotionTags()
        setupCamera()
        setupUI()
        updateUIForCurrentState()
        if isStickerCamera {
            showStickerMaskOverlay()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        startSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// 네비게이션 바를 숨긴 상태에서도 좌우 스와이프(뒤로가기) 제스처가 동작하도록 설정
        if let gesture = navigationController?.interactivePopGestureRecognizer {
            gesture.isEnabled = true
            gesture.delegate = self
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        stopSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = previewContainerView.bounds
        if stickerMaskView.superview != nil {
            updateStickerMaskPath()
        }
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("카메라를 찾을 수 없습니다")
            return
        }
        
        currentCamera = camera
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            try camera.lockForConfiguration()
            camera.videoZoomFactor = 1.3
            camera.unlockForConfiguration()
            
        } catch {
            print("카메라 설정 오류: \(error)")
        }
    }
    
    // MARK: - Session Management
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
    }
    
    func performCameraSwitchToFront() {
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("전면 카메라를 찾을 수 없습니다")
            return
        }
        
        currentCamera = frontCamera
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            try frontCamera.lockForConfiguration()
            frontCamera.videoZoomFactor = 1.3
            frontCamera.unlockForConfiguration()
        } catch {
            print("전면 카메라 설정 오류: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    CameraViewControllerWrapper()
        .ignoresSafeArea()
}

struct CameraViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CustomCameraViewController {
        let viewController = CustomCameraViewController()
        viewController.isStickerCamera = false
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CustomCameraViewController, context: Context) {
        // 업데이트 로직
    }
}
