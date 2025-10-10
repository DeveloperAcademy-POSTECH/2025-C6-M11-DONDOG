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
    func makeProfileSetupView() -> ProfileSetupView
    func makeInviteView() -> InviteView
    func makeCameraView(with feedViewModel: FeedViewModel) -> CameraView
    func makeFeedView() -> FeedView
    func makePostView(with postId: String, in roomId: String) -> PostView
}

final class ModuleFactory: ModuleFactoryProtocol {
    static let shared = ModuleFactory()
    private init() {}
    
    func makeAuthView() -> AuthView {
        let viewModel = AuthViewModel()
        let view = AuthView(viewModel: viewModel)
        return view
    }
    
    func makeProfileSetupView() -> ProfileSetupView {
        let viewModel = ProfileSetupViewModel()
        let view = ProfileSetupView(viewModel: viewModel)
        return view
    }
    
    func makeInviteView() -> InviteView {
        let viewModel = InviteViewModel()
        let view = InviteView(viewModel: viewModel)
        return view
    }
    
    func makeCameraView(with feedViewModel: FeedViewModel) -> CameraView {
        let cameraViewModel = CameraViewModel()
        cameraViewModel.delegate = feedViewModel
        return CameraView(viewModel: cameraViewModel)
    }
    
    func makeFeedView() -> FeedView {
        let viewModel = FeedViewModel()
        let view = FeedView(viewModel: viewModel)
        return view
    }
    
    func makePostView(with postId: String, in roomId: String) -> PostView {
        let viewModel = PostViewModel(postId: postId, roomId: roomId)
        let view = PostView(viewModel: viewModel)
        return view
    }
}
