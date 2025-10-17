//
//  ModuleFactoryProtocol.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI
import Combine

protocol ModuleFactoryProtocol {
    func makeWelcomeView() -> WelcomeView
    func makeAuthView(isWithDraw: Bool) -> AuthView
    func makeAuthNumberView() -> AuthNumberView
    func makeProfileSetupView() -> ProfileSetupView
    func makeInviteView(showSentHint: Bool) -> InviteView
    func makeCameraView(with feedViewModel: FeedViewModel) -> CameraView
    func makeFeedView() -> FeedView
    func makePostView(with postId: String, in roomId: String) -> PostView
    func makeSettingView() -> SettingView
    func makeEditProfileView() -> EditProfileView
    func makeArchiveView(in roomId: String) -> ArchiveView
}

final class ModuleFactory: ModuleFactoryProtocol {
    static let shared = ModuleFactory()
    private init() {}
    
    func makeWelcomeView() -> WelcomeView {
        let view = WelcomeView()
        return view
    }
    
    func makeAuthView(isWithDraw : Bool) -> AuthView {
        let viewModel = AuthViewModel(isWithDraw: isWithDraw)
        let view = AuthView(viewModel: viewModel)
        return view
    }
    
    func makeAuthNumberView() -> AuthNumberView {
        let viewModel = AuthNumberViewModel()
        let view = AuthNumberView(viewModel: viewModel)
        return view
    }
    
    func makeProfileSetupView() -> ProfileSetupView {
        let viewModel = ProfileSetupViewModel()
        let view = ProfileSetupView(viewModel: viewModel)
        return view
    }
    
    func makeInviteView(showSentHint: Bool) -> InviteView {
        let viewModel = InviteViewModel(showSentHint: showSentHint)
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

    func makeSettingView() -> SettingView {
        let viewModel = SettingViewModel()
        let view = SettingView(viewModel: viewModel)
        return view
    }
    
    func makeEditProfileView() -> EditProfileView {
        let viewModel = EditProfileViewModel()
        let view = EditProfileView(viewModel: viewModel)
        return view
    }
    
    func makeArchiveView(in roomId: String) -> ArchiveView {
        let viewModel = ArchiveViewModel(roomId: roomId)
        let view = ArchiveView(viewModel: viewModel)
        return view
    }
}
