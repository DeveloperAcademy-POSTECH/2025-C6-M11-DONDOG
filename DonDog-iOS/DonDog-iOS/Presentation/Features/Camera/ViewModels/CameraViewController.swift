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

class CustomCameraViewController: UIViewController {
    // MARK: - Properties
    weak var delegate: CustomCameraDelegate?
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var currentCamera: AVCaptureDevice?
    
    var isFrontOnly: Bool = false
    var stickerKeyword: String?
    var onStickerCreated: ((UIImage) -> Void)?

    private var isCapturingFront = true  // true: 전면 촬영, false: 후면 촬영
    private var frontImage: UIImage?
    private var backImage: UIImage?
    private var isCaptureButtonEnabled = true
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
    
    private func setupUI() {
        view.backgroundColor = .white
        
        setupCancelButton()
        setupBackground()
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
            previewContainerView.heightAnchor.constraint(equalTo: previewContainerView.widthAnchor, multiplier: 4.0/3.0)
        ])
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = previewContainerView.bounds
        previewContainerView.layer.addSublayer(videoPreviewLayer)

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

    private func setupGuideLabels() {
        setupFrontGuideLabel()
        setupBackGuideLabel()
    }

    private func setupFrontGuideLabel() {
        let (title, description) = (isFrontOnly ? "스티커 찍기📸\n" : "STEP 1. 셀카 찍기📸\n", isFrontOnly ? "\(stickerKeyword ?? "스티커")를 표현할 수 있는 표정과 포즈로 사진을 찍어주세요" : "전면 카메라로 얼굴이 잘 보이게 찍어주세요")
        configureGuideLabel(
            label: frontGuideMessageLabel,
            title: title,
            description: description,
            isHidden: false
        )
    }

    private func setupBackGuideLabel() {
        let (title, description) = ("STEP 2. 배경 찍기📸\n", "후면 카메라로 풍경이 잘 보이게 찍어주세요")
        configureGuideLabel(
            label: backGuideMessageLabel,
            title: title,
            description: description,
            isHidden: true
        )
    }

    private func configureGuideLabel(
        label: UILabel,
        title: String,
        description: String,
        isHidden: Bool
    ) {
        let attributedText = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .center
        
        let firstLine = NSAttributedString(
            string: title,
            attributes: [
                .font: UIFont(name: FontName.pretendardBold.rawValue, size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: Color.ddPrimaryBlue.uiColor,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        let secondLine = NSAttributedString(
            string: description,
            attributes: [
                .font: UIFont(name: FontName.pretendardRegular.rawValue, size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: Color.ddGray600.uiColor,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        attributedText.append(firstLine)
        attributedText.append(secondLine)
        
        label.attributedText = attributedText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = isHidden
        
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    @objc private func capturePhoto() {
        guard isCaptureButtonEnabled else {
            return
        }
        HapticManager.shared.heavy()
        isCaptureButtonEnabled = false
        captureButton.isEnabled = false
        captureButton.alpha = 0.5
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func switchToNextCamera() {
        if isCapturingFront {
            switchToBackCamera()
        } else {
            delegate?.didCompleteBothPhotos()
        }
    }
    
    private func switchToBackCamera() {
        capturedImageView.isHidden = true
        videoPreviewLayer.isHidden = false
        
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        
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
        
        isCapturingFront = false
        
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
                self.frontGuideMessageLabel.isHidden = false
                self.backGuideMessageLabel.isHidden = true
            } else {
                if self.isFrontOnly {
                    self.frontGuideMessageLabel.isHidden = false
                    self.backGuideMessageLabel.isHidden = true
                    self.captureButton.setTitle("전면 촬영", for: .normal)
                } else {
                    self.captureButton.setTitle("후면 촬영", for: .normal)
                    // 후면 촬영 안내 표시
                    self.frontGuideMessageLabel.isHidden = true
                    self.backGuideMessageLabel.isHidden = false
                }
                self.captureButton.setTitle("후면 촬영", for: .normal)
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
    
    func resetCameraState() {
        DispatchQueue.main.async {
            self.isCapturingFront = true
            self.frontImage = nil
            self.backImage = nil
            self.capturedImageView.isHidden = true
            self.videoPreviewLayer.isHidden = false
            self.isCaptureButtonEnabled = true
            self.captureButton.isEnabled = true
            self.captureButton.alpha = 1.0
            self.updateUIForCurrentState()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.performCameraSwitchToFront()
            }
        }
    }
    
    private func performCameraSwitchToFront() {
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

// MARK: - AVCapturePhotoCaptureDelegate
extension CustomCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
            var image = UIImage(data: imageData) else {
            print("이미지 변환 실패")
            return
        }
        
        if isCapturingFront {
            image = flipImageHorizontally(image) ?? image
            frontImage = image
            DispatchQueue.main.async {
                self.showCapturedImage(image)
            }
            if self.isFrontOnly {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.presentStickerConfirm(with: image)
                }
            } else {
                delegate?.didCaptureFrontImage(image)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.switchToNextCamera()
                }
            }
        } else {
            backImage = image
            delegate?.didCaptureBackImage(image)
            
            DispatchQueue.main.async {
                self.showCapturedImage(image)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.delegate?.didCompleteBothPhotos()
            }
        }
    }
    
    private func showCapturedImage(_ image: UIImage) {
        videoPreviewLayer.isHidden = true
        capturedImageView.image = image
        capturedImageView.isHidden = false
    }
    
    private func flipImageHorizontally(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let flippedImage = UIImage(
            cgImage: cgImage,
            scale: image.scale,
            orientation: .leftMirrored
        )
        
        return flippedImage
    }
    
    /// 스티커 이미지 컨펌 뷰로 넘기는 함수
    private func presentStickerConfirm(with image: UIImage) {
        Task { [weak self] in
            guard let self = self else { return }
            let sticker = await StickerService().makeSticker(from: image)
            let finalImage = sticker
            
            let confirmVC = UIHostingController(
                rootView: StickerConfirmView(
                    viewModel: StickerConfirmViewModel(
                        image: finalImage,
                        onDone: { [weak self] _ in
                            self?.dismissAllModals()
                        }
                    ),
                    source: .camera,
                    onRetake: { [weak self] in
                        self?.presentedViewController?.dismiss(animated: true) {
                            guard let self = self else { return }
                            self.resetCameraState()
                        }
                    },
                    onClose: { [weak self] in
                        self?.dismissAllModals()
                    }
                )
            )
            confirmVC.modalPresentationStyle = .fullScreen
            confirmVC.modalTransitionStyle = .crossDissolve
            self.present(confirmVC, animated: false)
        }
    }
    
    private func dismissAllModals(animated: Bool = true) {
        DispatchQueue.main.async {
            if let presenter = self.presentingViewController {
                presenter.dismiss(animated: animated)
            } else {
                self.dismiss(animated: animated)
            }
        }
    }
}
