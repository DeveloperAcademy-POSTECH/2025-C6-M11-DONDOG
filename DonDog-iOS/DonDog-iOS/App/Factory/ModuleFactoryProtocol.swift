//
//  ModuleFactoryProtocol.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI
import Combine

protocol ModuleFactoryProtocol {
    func makeAuthView() -> AuthView
    func makeInviteView() -> InviteView
    func makeCameraView() -> CameraView
    func makeFeedView() -> FeedView
}

final class ModuleFactory: ModuleFactoryProtocol {
    static let shared = ModuleFactory()
    private init() {}
    
    func makeAuthView() -> AuthView {
        let viewModel = AuthViewModel()
        let view = AuthView(viewModel: viewModel)
        return view
    }
    
    func makeInviteView() -> InviteView {
        let viewModel = InviteViewModel()
        let view = InviteView(viewModel: viewModel)
        return view
    }
    
    func makeCameraView() -> CameraView {
        let viewModel = CameraViewModel()
        let view = CameraView(viewModel: viewModel)
        return view
    }
    
    func makeFeedView() -> FeedView {
        let viewModel = FeedViewModel()
        let view = FeedView(viewModel: viewModel)
        return view
    }
}
