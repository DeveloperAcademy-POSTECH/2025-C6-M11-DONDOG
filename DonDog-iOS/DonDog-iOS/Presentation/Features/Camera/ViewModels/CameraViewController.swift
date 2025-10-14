//
//  CameraViewController.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/4/25.
//

import AVFoundation
import UIKit

// 카메라 델리게이트 프로토콜
protocol CustomCameraDelegate: AnyObject {
    func didCaptureFrontImage(_ image: UIImage)
    func didCaptureBackImage(_ image: UIImage)
    func didCancel()
    func didCompleteBothPhotos()
}

class CustomCameraViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: CustomCameraDelegate?
    
    // AVFoundation 관련
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var currentCamera: AVCaptureDevice?
    
    // 촬영 순서 관리
    private var isCapturingFront = true  // true: 전면 촬영, false: 후면 촬영
    private var frontImage: UIImage?
    private var backImage: UIImage?
    private var isCaptureButtonEnabled = true
    
    // UI Elements
    private let previewContainerView = UIView()
    private let capturedImageView = UIImageView()
    private let captureButton = UIButton()
    private let cancelButton = UIButton()
    private let switchCameraButton = UIButton()
    private let flashButton = UIButton()
    private let frontGuideMessageLabel = UILabel()
    private let backGuideMessageLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
        updateUIForCurrentState()  // 초기 UI 상태 설정
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        // 카메라 세션 생성
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        // 카메라 디바이스 설정
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("카메라를 찾을 수 없습니다")
            return
        }
        
        currentCamera = camera
        
        do {
            // 카메라 입력 생성
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // 사진 출력 설정
            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            // 전면 카메라 줌 배율 세팅
            try camera.lockForConfiguration()
            camera.videoZoomFactor = 1.3
            camera.unlockForConfiguration()
            
        } catch {
            print("카메라 설정 오류: \(error)")
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // UI 요소들 설정 (순서중요)
        setupCancelButton()
        setupBackground()
        //setupSwitchCameraButton()
        //setupFlashButton()
        setupGuideLabels()
        setupPreviewLayer()
        setupCaptureButton()
    }
    
    private func setupPreviewLayer() {
        previewContainerView.backgroundColor = .clear
        previewContainerView.layer.cornerRadius = 12
        previewContainerView.clipsToBounds = true
        
        view.addSubview(previewContainerView)
        previewContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            previewContainerView.topAnchor.constraint(equalTo: frontGuideMessageLabel.bottomAnchor, constant: 20),
            previewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            previewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // 3:4 비율 유지
            previewContainerView.heightAnchor.constraint(equalTo: previewContainerView.widthAnchor, multiplier: 4.0/3.0)
        ])
        
        // 비디오 프리뷰 레이어 추가
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = previewContainerView.bounds
        previewContainerView.layer.addSublayer(videoPreviewLayer)
        
        // 촬영된 이미지를 표시할 ImageView 추가
        capturedImageView.contentMode = .scaleAspectFill
        capturedImageView.clipsToBounds = true
        capturedImageView.isHidden = true  // 초기에는 숨김
        
        previewContainerView.addSubview(capturedImageView)
        capturedImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            capturedImageView.topAnchor.constraint(equalTo: previewContainerView.topAnchor),
            capturedImageView.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor),
            capturedImageView.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor),
            capturedImageView.bottomAnchor.constraint(equalTo: previewContainerView.bottomAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = previewContainerView.bounds
    }
    
    private func setupBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.ddWhite.cgColor,
            UIColor.ddSecondaryBlue.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.opacity = 0.35
        
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // 레이아웃이 변경될 때 그라디언트 크기 업데이트
        gradientLayer.frame = view.bounds
    }
    
    private func setupCaptureButton() {
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 36 
        captureButton.layer.borderWidth = 5
        captureButton.layer.borderColor = Color.ddPrimaryBlue.uiColor.cgColor
        
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        
        view.addSubview(captureButton)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            captureButton.widthAnchor.constraint(equalToConstant: 72),
            captureButton.heightAnchor.constraint(equalToConstant: 72)
        ])
    }
    
    private func setupCancelButton() {
        let chevronImage = UIImage(systemName: "chevron.left")
        let resizedImage = chevronImage?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        cancelButton.setImage(resizedImage, for: .normal)
        cancelButton.tintColor = Color.ddBlack.uiColor
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 11),
            cancelButton.widthAnchor.constraint(equalToConstant: 16),
            cancelButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupSwitchCameraButton() {
        switchCameraButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        switchCameraButton.tintColor = .white
        switchCameraButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        switchCameraButton.layer.cornerRadius = 25
        
        switchCameraButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        
        view.addSubview(switchCameraButton)
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            switchCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            switchCameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 50),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupFlashButton() {
        flashButton.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
        flashButton.tintColor = .white
        flashButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        flashButton.layer.cornerRadius = 25
        
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        
        view.addSubview(flashButton)
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flashButton.trailingAnchor.constraint(equalTo: switchCameraButton.leadingAnchor, constant: -10),
            flashButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            flashButton.widthAnchor.constraint(equalToConstant: 50),
            flashButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupGuideLabels() {
        let attributedText = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4  // 줄 간격
        paragraphStyle.alignment = .center
        
        let firstLine = NSAttributedString(
            string: "STEP 1. 셀카 찍기\n",
            attributes: [
                .font: UIFont(name: FontName.pretendardBold.rawValue, size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: Color.ddPrimaryBlue.uiColor,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        let secondLine = NSAttributedString(
            string: "전면 카메라로 얼굴이 잘 보이게 찍어주세요",
            attributes: [
                .font: UIFont(name: FontName.pretendardRegular.rawValue, size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: Color.ddGray600.uiColor,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        attributedText.append(firstLine)
        attributedText.append(secondLine)
        
        frontGuideMessageLabel.attributedText = attributedText
        frontGuideMessageLabel.textAlignment = .center
        frontGuideMessageLabel.numberOfLines = 0
        
        view.addSubview(frontGuideMessageLabel)
        frontGuideMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            frontGuideMessageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frontGuideMessageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            frontGuideMessageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            frontGuideMessageLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            frontGuideMessageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
        
        // 후면 촬영 안내 레이블
        let backAttributedText = NSMutableAttributedString()
        let backParagraphStyle = NSMutableParagraphStyle()
        backParagraphStyle.lineSpacing = 4  // 줄 간격
        backParagraphStyle.alignment = .center
        
        let backFirstLine = NSAttributedString(
            string: "STEP 2. 배경 찍기\n",
            attributes: [
                .font: UIFont(name: FontName.pretendardBold.rawValue, size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: Color.ddPrimaryBlue.uiColor,
                .paragraphStyle: backParagraphStyle
            ]
        )
        
        let backSecondLine = NSAttributedString(
            string: "후면 카메라로 풍경이 잘 보이게 찍어주세요",
            attributes: [
                .font: UIFont(name: FontName.pretendardRegular.rawValue, size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: Color.ddGray600.uiColor,
                .paragraphStyle: backParagraphStyle
            ]
        )
        
        backAttributedText.append(backFirstLine)
        backAttributedText.append(backSecondLine)
        
        backGuideMessageLabel.attributedText = backAttributedText
        backGuideMessageLabel.textAlignment = .center
        backGuideMessageLabel.numberOfLines = 0
        backGuideMessageLabel.isHidden = true  // 초기에는 숨김
        
        view.addSubview(backGuideMessageLabel)
        backGuideMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backGuideMessageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backGuideMessageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            backGuideMessageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            backGuideMessageLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            backGuideMessageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    @objc private func capturePhoto() {
        guard isCaptureButtonEnabled else {
            return
        }
        
        isCaptureButtonEnabled = false
        captureButton.isEnabled = false
        captureButton.alpha = 0.5
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // 카메라 전환 함수
    private func switchToNextCamera() {
        if isCapturingFront {
            // 전면 → 후면으로 전환
            switchToBackCamera()
        } else {
            // 후면 촬영 완료 → CaptionView로 이동
            delegate?.didCompleteBothPhotos()
        }
    }
    
    private func switchToBackCamera() {
        // 촬영된 이미지 숨기고 프리뷰 다시 보이기
        capturedImageView.isHidden = true
        videoPreviewLayer.isHidden = false
        
        // 기존 입력 제거
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        
        // 후면 카메라 설정
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("후면 카메라를 찾을 수 없습니다")
            return
        }
        
        currentCamera = backCamera
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("후면 카메라 설정 오류: \(error)")
        }
        
        // 상태 업데이트
        isCapturingFront = false
        
        // 촬영 버튼 다시 활성화
        isCaptureButtonEnabled = true
        captureButton.isEnabled = true
        captureButton.alpha = 1.0
        
        updateUIForCurrentState()
    }
    
    private func switchToFrontCamera() {
        capturedImageView.isHidden = true
        videoPreviewLayer.isHidden = false
        
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
        
        isCapturingFront = true
        frontImage = nil
        
        isCaptureButtonEnabled = true
        captureButton.isEnabled = true
        captureButton.alpha = 1.0
        
        updateUIForCurrentState()
    }
    
    private func updateUIForCurrentState() {
        DispatchQueue.main.async {
            if self.isCapturingFront {
                self.captureButton.setTitle("전면 촬영", for: .normal)
                // 전면 촬영 안내 표시
                self.frontGuideMessageLabel.isHidden = false
                self.backGuideMessageLabel.isHidden = true
            } else {
                self.captureButton.setTitle("후면 촬영", for: .normal)
                // 후면 촬영 안내 표시
                self.frontGuideMessageLabel.isHidden = true
                self.backGuideMessageLabel.isHidden = false
            }
        }
    }
    
    @objc private func cancelTapped() {
        if isCapturingFront {
            delegate?.didCancel()
        } else {
            switchToFrontCamera()
        }
    }
    
    @objc private func switchCamera() {
        // 카메라 전환 로직 (다음 단계에서 구현)
        print("카메라 전환")
    }
    
    @objc private func toggleFlash() {
        // 플래시 토글 로직 (다음 단계에서 구현)
        print("플래시 토글")
    }
    
    // MARK: - Session Management
    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
    }
    
    /// 촬영 상태를 완전히 초기화하여 전면 촬영부터 다시 시작할 수 있도록 함
    func resetCameraState() {
        DispatchQueue.main.async {
            // 1. 먼저 모든 상태를 전면 촬영 모드로 즉시 설정
            self.isCapturingFront = true
            self.frontImage = nil
            self.backImage = nil
            
            // 2. UI 상태를 즉시 전면 촬영 모드로 변경 (깜빡임 방지)
            self.capturedImageView.isHidden = true
            self.videoPreviewLayer.isHidden = false
            self.isCaptureButtonEnabled = true
            self.captureButton.isEnabled = true
            self.captureButton.alpha = 1.0
            
            // 3. UI를 즉시 업데이트 (Step1으로 표시)
            self.updateUIForCurrentState()
            
            // 4. 카메라 하드웨어 전환을 별도 스레드에서 처리 (UI 블로킹 방지)
            DispatchQueue.global(qos: .userInitiated).async {
                self.performCameraSwitchToFront()
            }
        }
    }
    
    /// 카메라 하드웨어만 전면으로 전환하는 메서드 (UI와 분리)
    private func performCameraSwitchToFront() {
        // 기존 입력 제거
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        
        // 전면 카메라 설정
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

// MARK: - AVCapturePhotoCaptureDelegate
extension CustomCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              var image = UIImage(data: imageData) else {
            print("이미지 변환 실패")
            return
        }
        
        if isCapturingFront {
            // 전면 촬영 완료 - 좌우 반전 (거울 모드)
            image = flipImageHorizontally(image) ?? image
            frontImage = image
            delegate?.didCaptureFrontImage(image)
            
            // 촬영된 이미지 표시
            DispatchQueue.main.async {
                self.showCapturedImage(image)
            }
            
            // 1초 후 후면 카메라로 전환
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.switchToNextCamera()
            }
        } else {
            // 후면 촬영 완료
            backImage = image
            delegate?.didCaptureBackImage(image)
            
            // 촬영된 이미지 표시
            DispatchQueue.main.async {
                self.showCapturedImage(image)
            }
            
            // 1초 후 CaptionView로 이동
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.delegate?.didCompleteBothPhotos()
            }
        }
    }
    
    // 촬영된 이미지를 화면에 표시하는 함수
    private func showCapturedImage(_ image: UIImage) {
        videoPreviewLayer.isHidden = true
        capturedImageView.image = image
        capturedImageView.isHidden = false
    }
    
    // 이미지 좌우 반전 함수
    private func flipImageHorizontally(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let flippedImage = UIImage(
            cgImage: cgImage,
            scale: image.scale,
            orientation: .leftMirrored
        )
        
        return flippedImage
    }
}

// MARK: - SwiftUI Preview
#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct CameraViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CustomCameraViewController {
        return CustomCameraViewController()
    }
    
    func updateUIViewController(_ uiViewController: CustomCameraViewController, context: Context) {
        // 업데이트 로직 (필요시)
    }
}

@available(iOS 13.0, *)
struct CameraViewController_Previews: PreviewProvider {
    static var previews: some View {
        CameraViewControllerPreview()
            .ignoresSafeArea()
    }
}
#endif
