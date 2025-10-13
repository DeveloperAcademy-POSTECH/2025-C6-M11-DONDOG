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
            
        } catch {
            print("카메라 설정 오류: \(error)")
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // UI 요소들 설정 (순서중요)
        setupCancelButton()
        //setupSwitchCameraButton()
        //setupFlashButton()
        setupGuideLabels()
        setupPreviewLayer()
        setupCaptureButton()
    }
    
    private func setupPreviewLayer() {
        previewContainerView.backgroundColor = .clear
        previewContainerView.layer.borderWidth = 2
        previewContainerView.layer.borderColor = UIColor.black.cgColor
        
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
    
    private func setupCaptureButton() {
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.layer.borderWidth = 5
        captureButton.layer.borderColor = UIColor.lightGray.cgColor
        
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        
        view.addSubview(captureButton)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func setupCancelButton() {
        cancelButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        cancelButton.tintColor = .black
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 30),
            cancelButton.heightAnchor.constraint(equalToConstant: 30)
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
        // 전면 촬영 안내 레이블
        frontGuideMessageLabel.text = "STEP 1.\n현재 모습을 촬영해주세요!"
        frontGuideMessageLabel.textColor = .black
        frontGuideMessageLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        frontGuideMessageLabel.textAlignment = .center
        frontGuideMessageLabel.numberOfLines = 0
        
        view.addSubview(frontGuideMessageLabel)
        frontGuideMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            frontGuideMessageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frontGuideMessageLabel.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 30),
            frontGuideMessageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            frontGuideMessageLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            frontGuideMessageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
        
        // 후면 촬영 안내 레이블
        backGuideMessageLabel.text = "STEP 2.\n풍경을 촬영해주세요!"
        backGuideMessageLabel.textColor = .black
        backGuideMessageLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        backGuideMessageLabel.textAlignment = .center
        backGuideMessageLabel.numberOfLines = 0
        backGuideMessageLabel.isHidden = true  // 초기에는 숨김
        
        view.addSubview(backGuideMessageLabel)
        backGuideMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backGuideMessageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backGuideMessageLabel.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 30),
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
