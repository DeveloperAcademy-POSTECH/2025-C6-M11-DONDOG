// swiftlint:disable file_length
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

// swiftlint:disable type_body_length
class CustomCameraViewController: UIViewController, UIGestureRecognizerDelegate {
    // MARK: - Properties
    weak var delegate: CustomCameraDelegate?
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var currentCamera: AVCaptureDevice?
    
    var isStickerCamera: Bool = false
    private let stickerMaskView = UIView()
    private let stickerMaskLayer = CAShapeLayer()
    var stickerKeyword: String?
    private var onStickerCreated: ((UIImage) -> Void)?
    
    private var isCapturingFront = true
    private var frontImage: UIImage?
    private var backImage: UIImage?
    private var isCaptureButtonEnabled = true
    private let previewContainerView = UIView()
    private let capturedImageView = UIImageView()
    private let captureButton = UIButton()
    private let innerCaptureCircle = UIView()
    private let cancelButton = UIButton()
    
    private let stickerGuideContainer = UIStackView()
    private let stickerTitleLabel = UILabel()
    private let stickerSubtitleLabel = UILabel()

    private let stepTitleLabel = UILabel()
    private let stepIndicatorContainer = UIView()
    private let step1Circle = UIView()
    private let step1Label = UILabel()
    private let stepDotsContainer = UIView()
    private let step2Circle = UIView()
    private let step2Label = UILabel()
    private let step1CheckmarkImageView = UIImageView()
    private let step2CheckmarkImageView = UIImageView()
    
    private let bottomButtonContainer = UIView()
    private let retakeButton = UIButton()
    private let nextButton = UIButton()
    
    private var isFrontPhotoConfirmed = false
    private var isBackPhotoConfirmed = false
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureModeFromEmotionTags()
        setupCamera()
        setupUI()
        updateUIForCurrentState()  // 초기 UI 상태 설정
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
        // 네비게이션 바를 숨긴 상태에서도 좌우 스와이프(뒤로가기) 제스처가 동작하도록 설정
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
    
    // MARK: - Camera Setup
    private func configureModeFromEmotionTags() {
        let tags = StickerEmotionTagManager.shared.emotionTags
        
        if tags.count >= 2 {
            isStickerCamera = true
            stickerKeyword = tags[1]
        } else {
            isStickerCamera = false
            stickerKeyword = nil
        }
    }

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
        if isStickerCamera {
            setupStickerGuide()
        } else {
            setupStepIndicator()
        }
        setupPreviewLayer()
        setupCaptureButton()
        if !isStickerCamera {
            setupBottomButtons()
        }
    }
    
    private func setupPreviewLayer() {
        previewContainerView.backgroundColor = .clear
        previewContainerView.clipsToBounds = true
        previewContainerView.layer.cornerRadius = 12
        
        view.addSubview(previewContainerView)
        previewContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        let topAnchor: NSLayoutYAxisAnchor
        let topSpacing: CGFloat
        if isStickerCamera {
            if stickerGuideContainer.superview != nil {
                topAnchor = stickerGuideContainer.bottomAnchor
                topSpacing = 24
            } else {
                topAnchor = cancelButton.bottomAnchor
                topSpacing = 24
            }
        } else {
            topAnchor = stepIndicatorContainer.bottomAnchor
            topSpacing = 20
        }
        
        NSLayoutConstraint.activate([
            previewContainerView.topAnchor.constraint(equalTo: topAnchor, constant: topSpacing),
            previewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            previewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
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
        
        if stickerMaskView.superview != nil {
            updateStickerMaskPath()
        }
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
    
    // MARK: - 스티커 안내 UI
    private func showStickerMaskOverlay() {
        // 이미 추가되어 있으면 중복 추가 방지
        if stickerMaskView.superview != nil { return }
        
        stickerMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        // 마스크가 표시되는 동안 서브타이틀을 더 옅은 색으로 표시
        stickerSubtitleLabel.textColor = .ppGray300
        stickerMaskView.translatesAutoresizingMaskIntoConstraints = false
        stickerMaskView.isUserInteractionEnabled = false
        view.addSubview(stickerMaskView)
        
        NSLayoutConstraint.activate([
            stickerMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            stickerMaskView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stickerMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickerMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 초기 레이아웃 강제 적용 후 마스크 경로 설정
        view.layoutIfNeeded()
        updateStickerMaskPath()
        
        // 처음엔 바로 보이게
        stickerMaskView.alpha = 1.0
        
        // 0.8초 동안 유지 후 0.4초 동안 easeOut으로 사라지기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                options: .curveEaseOut,
                animations: {
                    self.stickerMaskView.alpha = 0.0
                },
                completion: { _ in
                    self.stickerMaskView.removeFromSuperview()
                    // 마스크가 사라지면 서브타이틀 색을 진하게 변경
                    self.stickerSubtitleLabel.textColor = .ppGray700
                }
            )
        }
    }

    private func setupStickerGuide() {
        guard isStickerCamera else { return }
        let tagText = stickerKeyword ?? StickerEmotionTagManager.shared.emotionTags.last ?? ""

        stickerGuideContainer.axis = .vertical
        stickerGuideContainer.alignment = .center
        stickerGuideContainer.distribution = .fill
        stickerGuideContainer.spacing = 4

        stickerTitleLabel.text = tagText
        stickerTitleLabel.font = UIFont(name: FontName.sejongGeulggot.rawValue, size: 32) ?? UIFont.systemFont(ofSize: 32, weight: .bold)
        stickerTitleLabel.textColor = .ppPrime
        stickerTitleLabel.textAlignment = .center

        stickerSubtitleLabel.text = "스티커에 어울리는 사진을 찍어주세요"
        stickerSubtitleLabel.font = UIFont(name: FontName.pretendardRegular.rawValue, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .regular)
        stickerSubtitleLabel.textColor = .ppGray300
        stickerSubtitleLabel.textAlignment = .center

        stickerGuideContainer.addArrangedSubview(stickerTitleLabel)
        stickerGuideContainer.addArrangedSubview(stickerSubtitleLabel)

        view.addSubview(stickerGuideContainer)
        stickerGuideContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stickerGuideContainer.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 16),
            stickerGuideContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stickerGuideContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func updateStickerMaskPath() {
        let bounds = stickerMaskView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        let path = UIBezierPath(rect: bounds)
        
        let ellipseWidth: CGFloat = 300
        let ellipseHeight: CGFloat = 350
        let ellipseRect = CGRect(
            x: (bounds.width - ellipseWidth) / 2,
            y: (bounds.height - ellipseHeight) / 2,
            width: ellipseWidth,
            height: ellipseHeight
        )
        
        let holePath = UIBezierPath(ovalIn: ellipseRect)
        path.append(holePath)
        
        stickerMaskLayer.path = path.cgPath
        stickerMaskLayer.fillRule = .evenOdd   // 구멍 만들기 포인트
        stickerMaskView.layer.mask = stickerMaskLayer
    }
    
    // MARK: - Step 안내 UI
    private func setupStepIndicator() {
        setupStepTitleLabel()
        setupStepIndicatorContainer()
        setupStep1Circle()
        setupStepDots()
        setupStep2Circle()
        
        updateStepIndicator()
    }
    
    // 1. Step 타이틀 라벨 설정
    private func setupStepTitleLabel() {
        stepTitleLabel.text = "Step"
        stepTitleLabel.font = UIFont(name: FontName.pretendardBold.rawValue, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        stepTitleLabel.textColor = .ddBlack
        stepTitleLabel.textAlignment = .center
        
        view.addSubview(stepTitleLabel)
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stepTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepTitleLabel.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 8)
        ])
    }

    // 2. Step 인디케이터 컨테이너 설정
    private func setupStepIndicatorContainer() {
        view.addSubview(stepIndicatorContainer)
        stepIndicatorContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stepIndicatorContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepIndicatorContainer.topAnchor.constraint(equalTo: stepTitleLabel.bottomAnchor, constant: 8),
            stepIndicatorContainer.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // 3. Step 1 원, 라벨, 체크 마크 설정
    private func setupStep1Circle() {
        // Step 1 원
        step1Circle.backgroundColor = .ddAlert
        step1Circle.layer.cornerRadius = 12
        stepIndicatorContainer.addSubview(step1Circle)
        step1Circle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step1Circle.leadingAnchor.constraint(equalTo: stepIndicatorContainer.leadingAnchor),
            step1Circle.centerYAnchor.constraint(equalTo: stepIndicatorContainer.centerYAnchor),
            step1Circle.widthAnchor.constraint(equalToConstant: 24),
            step1Circle.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Step 1 라벨
        step1Label.text = "1"
        step1Label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        step1Label.textColor = .white
        step1Label.textAlignment = .center
        step1Circle.addSubview(step1Label)
        step1Label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step1Label.centerXAnchor.constraint(equalTo: step1Circle.centerXAnchor),
            step1Label.centerYAnchor.constraint(equalTo: step1Circle.centerYAnchor)
        ])
        
        // Step 1 체크 마크
        step1CheckmarkImageView.image = UIImage(systemName: "checkmark")
        step1CheckmarkImageView.tintColor = .white
        step1CheckmarkImageView.contentMode = .scaleAspectFit
        step1CheckmarkImageView.isHidden = true
        
        step1Circle.addSubview(step1CheckmarkImageView)
        step1CheckmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step1CheckmarkImageView.centerXAnchor.constraint(equalTo: step1Circle.centerXAnchor),
            step1CheckmarkImageView.centerYAnchor.constraint(equalTo: step1Circle.centerYAnchor),
            step1CheckmarkImageView.widthAnchor.constraint(equalToConstant: 14),
            step1CheckmarkImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    // 4. 점 세 개 설정
    private func setupStepDots() {
        stepIndicatorContainer.addSubview(stepDotsContainer)
        stepDotsContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stepDotsContainer.leadingAnchor.constraint(equalTo: step1Circle.trailingAnchor, constant: 8),
            stepDotsContainer.centerYAnchor.constraint(equalTo: stepIndicatorContainer.centerYAnchor),
            stepDotsContainer.widthAnchor.constraint(equalToConstant: 24),
            stepDotsContainer.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // 점 세 개 생성
        for i in 0..<3 {
            let dot = UIView()
            dot.backgroundColor = .ddGray400
            dot.layer.cornerRadius = 2
            stepDotsContainer.addSubview(dot)
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.centerYAnchor.constraint(equalTo: stepDotsContainer.centerYAnchor),
                dot.leadingAnchor.constraint(equalTo: stepDotsContainer.leadingAnchor, constant: CGFloat(i * 8)),
                dot.widthAnchor.constraint(equalToConstant: 4),
                dot.heightAnchor.constraint(equalToConstant: 4)
            ])
        }
    }

    // 5. Step 2 원, 라벨, 체크 마크 설정
    private func setupStep2Circle() {
        // Step 2 원
        step2Circle.backgroundColor = .ddGray300
        step2Circle.layer.cornerRadius = 12
        stepIndicatorContainer.addSubview(step2Circle)
        step2Circle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step2Circle.leadingAnchor.constraint(equalTo: stepDotsContainer.trailingAnchor, constant: 8),
            step2Circle.centerYAnchor.constraint(equalTo: stepIndicatorContainer.centerYAnchor),
            step2Circle.trailingAnchor.constraint(equalTo: stepIndicatorContainer.trailingAnchor),
            step2Circle.widthAnchor.constraint(equalToConstant: 24),
            step2Circle.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Step 2 라벨
        step2Label.text = "2"
        step2Label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        step2Label.textColor = .white
        step2Label.textAlignment = .center
        step2Circle.addSubview(step2Label)
        step2Label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step2Label.centerXAnchor.constraint(equalTo: step2Circle.centerXAnchor),
            step2Label.centerYAnchor.constraint(equalTo: step2Circle.centerYAnchor)
        ])
        
        // Step 2 체크 마크
        step2CheckmarkImageView.image = UIImage(systemName: "checkmark")
        step2CheckmarkImageView.tintColor = .white
        step2CheckmarkImageView.contentMode = .scaleAspectFit
        step2CheckmarkImageView.isHidden = true
        
        step2Circle.addSubview(step2CheckmarkImageView)
        step2CheckmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step2CheckmarkImageView.centerXAnchor.constraint(equalTo: step2Circle.centerXAnchor),
            step2CheckmarkImageView.centerYAnchor.constraint(equalTo: step2Circle.centerYAnchor),
            step2CheckmarkImageView.widthAnchor.constraint(equalToConstant: 14),
            step2CheckmarkImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    // MARK: - 상태 업데이트
    // Step 인디케이터 상태 업데이트
    private func updateStepIndicator() {
        guard !isStickerCamera else { return }
        
        if isCapturingFront {
            // 전면 촬영 중
            step1Circle.backgroundColor = .ddAlert
            step1Label.isHidden = false
            step1CheckmarkImageView.isHidden = true
            step1Label.textColor = .white
            
            step2Circle.backgroundColor = .ddGray300
            step2Label.isHidden = false
            step2CheckmarkImageView.isHidden = true
            step2Label.textColor = .white
        } else {
            // 후면 촬영 중
            // Step 1 완료 상태 유지 (체크 마크 표시)
            step1Circle.backgroundColor = .ddGray300
            step1Label.isHidden = true
            step1CheckmarkImageView.isHidden = false // 체크 마크 유지
            
            // Step 2 활성화 (체크 마크가 아닌 숫자 표시)
            step2Circle.backgroundColor = .ddAlert
            step2Label.isHidden = false
            step2CheckmarkImageView.isHidden = true
            step2Label.textColor = .white
        }
    }

    private func updateUIForCurrentState() {
        DispatchQueue.main.async {
            if self.isCapturingFront {
                self.captureButton.setTitle("전면 촬영", for: .normal)
            } else {
                if self.isStickerCamera {
                    self.captureButton.setTitle("전면 촬영", for: .normal)
                } else {
                    self.captureButton.setTitle("후면 촬영", for: .normal)
                }
                self.captureButton.setTitle("후면 촬영", for: .normal)
            }
            
            // Step 인디케이터 업데이트 추가
            self.updateStepIndicator()
        }
    }
    
    private func setupCaptureButton() {
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 36
        captureButton.layer.borderWidth = 3
        captureButton.layer.borderColor = Color.ppPrime.uiColor.cgColor

        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)

        innerCaptureCircle.backgroundColor = Color.ppPrime.uiColor
        innerCaptureCircle.layer.cornerRadius = 28
        innerCaptureCircle.clipsToBounds = true
        innerCaptureCircle.isUserInteractionEnabled = false

        captureButton.addSubview(innerCaptureCircle)
        innerCaptureCircle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerCaptureCircle.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            innerCaptureCircle.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            innerCaptureCircle.widthAnchor.constraint(equalToConstant: 56),
            innerCaptureCircle.heightAnchor.constraint(equalToConstant: 56)
        ])

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
    
    private func setupBottomButtons() {
        // 버튼 컨테이너
        view.addSubview(bottomButtonContainer)
        bottomButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomButtonContainer.isHidden = true // 초기에는 숨김
        
        NSLayoutConstraint.activate([
            bottomButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            bottomButtonContainer.heightAnchor.constraint(equalToConstant: 52)
        ])
        
        // 다시 찍기 버튼
        retakeButton.backgroundColor = .ddGray300
        retakeButton.layer.cornerRadius = 12
        retakeButton.setTitle("다시 찍기", for: .normal)
        retakeButton.setTitleColor(.ddWhite, for: .normal)
        retakeButton.titleLabel?.font = UIFont(name: FontName.pretendardSemiBold.rawValue, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        // 다시 찍기 아이콘 추가 (원형 화살표)
        let retakeIcon = UIImage(systemName: "arrow.counterclockwise")
        retakeButton.setImage(retakeIcon, for: .normal)
        retakeButton.tintColor = .ddWhite
        retakeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        retakeButton.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
        
        bottomButtonContainer.addSubview(retakeButton)
        retakeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 다음 버튼
        nextButton.backgroundColor = .ddBlack
        nextButton.layer.cornerRadius = 12
        nextButton.setTitle("다음", for: .normal)
        nextButton.setTitleColor(.ddWhite, for: .normal)
        nextButton.titleLabel?.font = UIFont(name: FontName.pretendardSemiBold.rawValue, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
        nextButton.addTarget(self, action: #selector(proceedToNextStep), for: .touchUpInside)
        
        bottomButtonContainer.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 버튼 레이아웃
        NSLayoutConstraint.activate([
            retakeButton.leadingAnchor.constraint(equalTo: bottomButtonContainer.leadingAnchor),
            retakeButton.centerYAnchor.constraint(equalTo: bottomButtonContainer.centerYAnchor),
            retakeButton.widthAnchor.constraint(equalTo: nextButton.widthAnchor),
            retakeButton.heightAnchor.constraint(equalToConstant: 52),
            
            nextButton.leadingAnchor.constraint(equalTo: retakeButton.trailingAnchor, constant: 12),
            nextButton.trailingAnchor.constraint(equalTo: bottomButtonContainer.trailingAnchor),
            nextButton.centerYAnchor.constraint(equalTo: bottomButtonContainer.centerYAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    @objc private func retakePhoto() {
        if isCapturingFront {
            // 전면 촬영 다시 찍기
            isFrontPhotoConfirmed = false
            frontImage = nil
            
            updateUIForFrontPhotoConfirmation(isConfirmed: false)
            
            capturedImageView.isHidden = true
            videoPreviewLayer.isHidden = false
            
            isCaptureButtonEnabled = true
            captureButton.isEnabled = true
            captureButton.alpha = 1.0
        } else {
            // 후면 촬영 다시 찍기
            isBackPhotoConfirmed = false
            backImage = nil
            
            updateUIForBackPhotoConfirmation(isConfirmed: false)
            
            capturedImageView.isHidden = true
            videoPreviewLayer.isHidden = false
            
            isCaptureButtonEnabled = true
            captureButton.isEnabled = true
            captureButton.alpha = 1.0
        }
    }

    private func updateUIForFrontPhotoConfirmation(isConfirmed: Bool) {
        guard !isStickerCamera else { return }
        
        isFrontPhotoConfirmed = isConfirmed
        DispatchQueue.main.async {
            if isConfirmed {
                // 1. Step 타이틀 변경
                self.stepTitleLabel.text = "사진을 확인해 주세요"
                
                // 2. Step 1 원에 체크 마크 표시
                self.step1Label.isHidden = true
                self.step1CheckmarkImageView.isHidden = false
                self.step1Circle.backgroundColor = .ddAlert // 빨간색 유지
                
                // 3. 하단 버튼 표시
                self.bottomButtonContainer.isHidden = false
                self.captureButton.isHidden = true // 촬영 버튼 숨김
            } else {
                // 리셋: 원래 상태로
                self.stepTitleLabel.text = "Step"
                self.step1Label.isHidden = false
                self.step1CheckmarkImageView.isHidden = true
                self.bottomButtonContainer.isHidden = true
                self.captureButton.isHidden = false
            }
        }
    }
    
    private func updateUIForBackPhotoConfirmation(isConfirmed: Bool) {
        isBackPhotoConfirmed = isConfirmed
        
        DispatchQueue.main.async {
            if isConfirmed {
                // 1. Step 타이틀 변경
                self.stepTitleLabel.text = "사진을 확인해 주세요"
                
                // 2. Step 2 원에 체크 마크 표시
                self.step2Label.isHidden = true
                self.step2CheckmarkImageView.isHidden = false
                self.step2Circle.backgroundColor = .ddAlert // 빨간색 유지
                
                // 3. 하단 버튼 표시
                self.bottomButtonContainer.isHidden = false
                self.captureButton.isHidden = true // 촬영 버튼 숨김
            } else {
                // 리셋: 원래 상태로
                self.stepTitleLabel.text = "Step"
                self.step2Label.isHidden = false
                self.step2CheckmarkImageView.isHidden = true
                self.bottomButtonContainer.isHidden = true
                self.captureButton.isHidden = false
            }
        }
    }
    
    @objc private func proceedToNextStep() {
        if isCapturingFront {
            // 전면 촬영 완료 후 "다음" 버튼: 후면 촬영으로 전환
            guard let frontImage = frontImage else { return }
            
            delegate?.didCaptureFrontImage(frontImage)
            switchToBackCamera()
        } else {
            // 후면 촬영 완료 후 "다음" 버튼: 최종 완료
            guard let backImage = backImage else { return }
            
            delegate?.didCompleteBothPhotos()
        }
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
        
        // Step2 UI 상태로 전환
        updateUIForBackCamera()
    }
    
    private func updateUIForBackCamera() {
        DispatchQueue.main.async {
            // Step 타이틀 리셋
            self.stepTitleLabel.text = "Step"
            
            // Step 인디케이터 업데이트 (Step 2 활성화, Step 1 체크 마크 유지)
            self.updateStepIndicator()
            
            // 하단 버튼 숨기고 capture 버튼 표시
            self.bottomButtonContainer.isHidden = true
            self.captureButton.isHidden = false
            
            // 전면 촬영 확인 상태 리셋
            self.isFrontPhotoConfirmed = false
        }
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
            
            self.isFrontPhotoConfirmed = false
            self.isBackPhotoConfirmed = false
            
            self.stepTitleLabel.text = "Step"
            
            self.step1Label.isHidden = false
            self.step1CheckmarkImageView.isHidden = true
            self.step1Circle.backgroundColor = .ddAlert
            self.step1Label.textColor = .white
            
            self.step2Label.isHidden = false
            self.step2CheckmarkImageView.isHidden = true
            self.step2Circle.backgroundColor = .ddGray300
            self.step2Label.textColor = .white
            
            self.bottomButtonContainer.isHidden = true
            self.captureButton.isHidden = false
            
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
// swiftlint:enable type_body_length

// MARK: - AVCapturePhotoCaptureDelegate
extension CustomCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(), var image = UIImage(data: imageData) else {
            print("이미지 변환 실패")
            return
        }
        
        if isCapturingFront {
            // 전면 촬영 완료
            image = flipImageHorizontally(image) ?? image
            frontImage = image
            
            DispatchQueue.main.async {
                // 1. 찍은 사진 표시
                self.showCapturedImage(image)
                
                // 2-4. UI 업데이트
                self.updateUIForFrontPhotoConfirmation(isConfirmed: true)
            }
            
            // 스티커 모드인 경우에만 자동 진행
            if self.isStickerCamera {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.presentStickerConfirm(with: image)
                }
            }
            // 일반 모드는 사용자가 "다음" 버튼을 눌러야 진행
            
        } else {
            // 후면 촬영 완료
            backImage = image
            delegate?.didCaptureBackImage(image)
            
            DispatchQueue.main.async {
                // 1. 찍은 사진 표시
                self.showCapturedImage(image)
                
                // 2-4. UI 업데이트 (전면 촬영과 동일)
                self.updateUIForBackPhotoConfirmation(isConfirmed: true)
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
                        image: finalImage
                    ),
                    route: .camera,
                    onRetake: { [weak self] in
                        guard let self = self else { return }
                        self.presentedViewController?.dismiss(animated: true) {
                            self.navigationController?.setNavigationBarHidden(true, animated: false)
                            self.navigationItem.hidesBackButton = true
                            self.resetCameraState()
                        }
                    },
                    onComplete: { [weak self] in
                        guard let self = self else { return }
                        self.dismiss(animated: true) {
                            self.delegate?.didCancel()
                        }
                    },
                    onUploaded: { tags in
                        Task {
                            await StickerGridService.shared.reloadSticker(tags: tags)
                        }
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
