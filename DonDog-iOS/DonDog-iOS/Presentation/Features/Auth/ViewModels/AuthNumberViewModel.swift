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

final class AuthNumberViewModel: ObservableObject {
    private weak var coordinator: AppCoordinator?

    init(coordinator: AppCoordinator? = nil) {
        self.coordinator = coordinator
    }

    func attach(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    @Published var verificationCode: String = ""
    @Published var verificationID: String?
    
    @Published var message: String = ""
    @Published var isLoading: Bool = false
    
    @Published var codeError: String? = nil
    
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
        self.codeError = nil
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: self.verificationCode
        )
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("[Auth][signIn] error: \(error.localizedDescription)")
                    self.codeError = "인증번호를 다시 확인해주세요."
                } else {
                    self.codeError = nil
                    print("로그인 성공")
                    if let user = Auth.auth().currentUser {
                        print("전화번호:", user.phoneNumber ?? "없음")
                    }
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
                    self.isLoading = false
                } else {
                    self.coordinator?.replaceRoot(.profileSetup)
                    self.isLoading = false
                }
            }
        }
    }
    
}
