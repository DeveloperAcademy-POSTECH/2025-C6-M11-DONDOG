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
    @Published var shouldCloseMenu: Bool = false
    
    @Published var phoneError: String? = nil
    @Published var codeError: String? = nil
    
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
                    self.message = "익명 로그인 성공! uid: \(user.uid)"
                }
            }
        }
    }
    
    //인증번호(SMS) 요청
    func sendCode() {
        let digits = userPhoneNumber.filter { $0.isNumber }
        let isValidKRMobile = NSPredicate(format: "SELF MATCHES %@", "^010\\d{8}$").evaluate(with: digits)
        guard isValidKRMobile else {
            self.phoneError = "전화번호는 010으로 시작하는 11자리 숫자예요"
            return
        }
        var formattedDigits = digits
        if formattedDigits.hasPrefix("010") {
            formattedDigits.removeFirst()
        }
        let formattedDigitsWithCode = "+82" + formattedDigits
        print("서버로 보내는 전화번호: \(formattedDigitsWithCode)")

        self.isLoading = true
        self.message = ""
        self.phoneError = nil
        self.codeError = nil

        // Firebase Phone Auth: reCAPTCHA/기기 검증 플로우는 내부에서 처리됨
        PhoneAuthProvider.provider().verifyPhoneNumber(formattedDigitsWithCode, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let nsError = error as NSError?,
                   let code = AuthErrorCode(rawValue: nsError.code) {
                    if code == .invalidPhoneNumber {
                        self.phoneError = "전화번호는 010으로 시작하는 11자리 숫자예요"
                    } else {
                        self.phoneError = "문제가 생겼어요. 잠시 후 다시 시도해 주세요"
                    }
                    self.isCodeSent = false
                    return
                }

                self.verificationID = verificationID
                if let id = verificationID {
                    UserDefaults.standard.set(id, forKey: "authVerificationID")
                }
                self.isCodeSent = true
                self.phoneError = nil
            }
        }
    }
    
    /// 인증번호로 로그인
    func logIn() {
        // verifyPhoneNumber로 받은 verificationID 확보
        let storedID = UserDefaults.standard.string(forKey: "authVerificationID")
        guard let verificationID = self.verificationID ?? storedID else {
            self.codeError = "문제가 생겼어요. 잠시 후 다시 시도해 주세요."
            return
        }
        
        self.isLoading = true
        self.message = ""
        self.phoneError = nil
        self.codeError = nil
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: self.verificationCode
        )
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("[Auth][signIn] error: \(error.localizedDescription)")
                    self.codeError = "인증번호를 다시 확인해주세요."
                } else {
                    self.codeError = nil
                    self.routeAfterSignIn()
                }
            }
        }
    }
    
    private func routeAfterSignIn() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("Users").document(uid)

        docRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("[Auth][routeAfterSignIn] fetch user doc error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.coordinator?.push(.profileSetup)
                }
                return
            }

            let exists = (snapshot?.exists == true)
            DispatchQueue.main.async {
                if exists {
                    self.coordinator?.replaceRoot(.feed)
                } else {
                    self.coordinator?.replaceRoot(.profileSetup)
                }
            }
        }
    }
}
