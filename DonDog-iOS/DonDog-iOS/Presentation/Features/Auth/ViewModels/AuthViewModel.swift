//
//  AuthViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class AuthViewModel: ObservableObject {
    private weak var coordinator: AppCoordinator?

        init(coordinator: AppCoordinator? = nil) {
            self.coordinator = coordinator
        }

        func attach(coordinator: AppCoordinator) {
            self.coordinator = coordinator
        }
    
    @Published var userPhoneNumber: String = ""
    @Published var verificationCode: String = ""
    @Published var verificationID: String?
    
    @Published var message: String = ""
    @Published var isCodeSent: Bool = false
    @Published var isLoading: Bool = false
    @Published var isLoggedIn: Bool = false
    @Published var shouldCloseMenu: Bool = false
    
    func signInAnonymously() {
        self.isLoading = true
        self.message = ""
        
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.message = "익명 로그인 실패: \(error.localizedDescription)"
                    return
                }
                
                if let user = result?.user {
                    self.isLoggedIn = true
                    self.message = "익명 로그인 성공! uid: \(user.uid)"
                }
            }
        }
    }
    
    // MARK: - Phone number helpers
    /// 숫자만 남긴다 (하이픈/공백/문자 제거)
    private func digitsOnly(_ s: String) -> String {
        return s.filter { $0.isNumber }
    }
    
    /// 사용자가 01012345678 형식으로 입력하면 서버에는 +821012345678 형식으로 전달
    var serverPhoneNumber: String {
        let digits = digitsOnly(userPhoneNumber)
        
        // 빈 값 처리
        guard !digits.isEmpty else { return "" }
        
        // 0으로 시작(국내) -> +82 + (앞의 0 제거)
        if digits.hasPrefix("0") {
            let withoutLeadingZero = String(digits.dropFirst())
            return "+82" + withoutLeadingZero
        }
        
        // 이미 국가코드 형태(82...) -> +82...
        if digits.hasPrefix("82") {
            return "+" + digits
        }
        
        // 그 외(가급적 한국 번호로 간주)
        return "+82" + digits
    }
    
    // MARK: - Actions
    /// 인증번호(SMS) 요청
    func sendCode() {
        // 기본 검증
        let number = serverPhoneNumber
        guard number.count >= 10 else {
            self.message = "전화번호 형식이 올바르지 않습니다."
            return
        }
        
        self.isLoading = true
        self.message = ""
        
        // Firebase Phone Auth: reCAPTCHA/기기 검증 플로우는 내부에서 처리됨
        PhoneAuthProvider.provider().verifyPhoneNumber(number, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let nsError = error as NSError?,
                   let code = AuthErrorCode(rawValue: nsError.code) {
                    switch code {
                    case .invalidPhoneNumber:
                        self.message = "전화번호 형식이 올바르지 않아요."
                    case .sessionExpired:
                        self.message = "인증 세션이 만료되었어요. 다시 시도해 주세요."
                    case .quotaExceeded, .tooManyRequests:
                        self.message = "요청이 많아요. 잠시 후 다시 시도해 주세요."
                    case .captchaCheckFailed:
                        self.message = "reCAPTCHA 인증에 실패했어요. 네트워크를 확인하고 다시 시도해 주세요."
                    default:
                        self.message = "[인증번호 요청 실패] \(code) - \(nsError.localizedDescription)"
                    }
                    self.isCodeSent = false
                    return
                } else if let error = error {
                    self.message = "[인증번호 요청 실패] \(error.localizedDescription)"
                    self.isCodeSent = false
                    return
                }
                
                self.verificationID = verificationID
                if let id = verificationID {
                    UserDefaults.standard.set(id, forKey: "authVerificationID")
                }
                self.isCodeSent = true
                self.message = "인증번호가 전송되었어요."
            }
        }
    }
    
    /// 인증번호로 로그인
    func logIn() {
        // verifyPhoneNumber로 받은 verificationID 확보
        let storedID = UserDefaults.standard.string(forKey: "authVerificationID")
        guard let verificationID = self.verificationID ?? storedID else {
            self.message = "인증 ID를 찾을 수 없습니다."
            return
        }
        
        self.isLoading = true
        self.message = ""
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: self.verificationCode
        )
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.message = "로그인 실패: \(error.localizedDescription)"
                } else {
                    self.isLoggedIn = true
                    self.message = "로그인 성공!"
                }
            }
        }
    }
}
