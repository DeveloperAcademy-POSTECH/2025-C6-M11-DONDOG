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
    
    //인증번호(SMS) 요청
    func sendCode() {
        // 기본 검증: 한국 휴대폰 010으로 시작 + 총 11자리(뒤 8자리 숫자)
        let digits = userPhoneNumber.filter { $0.isNumber }
        let isValidKRMobile = NSPredicate(format: "SELF MATCHES %@", "^010\\d{8}$").evaluate(with: digits)
        guard isValidKRMobile else {
            self.message = "전화번호는 010으로 시작하는 11자리여야 해요."
            return
        }
        // 앞의 0 제거 후 +82 붙이기 → +8210xxxx....
        let withoutLeadingZero = String(digits.dropFirst())
        let number = "+82" + withoutLeadingZero
        print("서버로 보내는 전화번호: \(number)")
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
                        self.message = "전화번호 형식이 맞지 않아요. 010-0000-0000 형식으로 입력해 주세요."
                    case .sessionExpired:
                        self.message = "인증 시간이 만료되었어요. 다시 시도해 주세요."
                    case .quotaExceeded, .tooManyRequests:
                        self.message = "요청이 많아요. 1~2분 후에 다시 시도해 주세요."
                    case .captchaCheckFailed:
                        self.message = "인증을 확인하지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요."
                    default:
                        print("[Auth][verifyPhoneNumber] error: code=\(code), desc=\(nsError.localizedDescription)")
                        self.message = "문제가 생겼어요. 잠시 후 다시 시도해 주세요."
                    }
                    self.isCodeSent = false
                    return
                } else if let error = error {
                    print("[Auth][verifyPhoneNumber] error: \(error.localizedDescription)")
                    self.message = "문제가 생겼어요. 잠시 후 다시 시도해 주세요."
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
            self.message = "인증을 다시 요청해주세요."
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
