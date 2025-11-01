//
//  ModuleFactoryProtocol.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import SwiftUI

protocol ModuleFactoryProtocol {
    func makeWelcomeView() -> WelcomeView
    func makeAuthView(isWithDraw: Bool) -> AuthView
    func makeAuthNumberView(isNumberWithdraw: Bool) -> AuthNumberView
    func makeProfileSetupView() -> ProfileSetupView
    func makeInviteView(showSentHint: Bool) -> InviteView
    func makeCameraView(with feedViewModel: FeedViewModel) -> CameraView
    func makeFeedView() -> FeedView
    func makeSettingView() -> SettingView
    func makeEditProfileView() -> EditProfileView
    func makeArchiveView() -> ArchiveView
    func makePostView(with posts: [PostData], for postType: PostType) -> PostView
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
    
    func makeAuthNumberView(isNumberWithdraw: Bool) -> AuthNumberView {
        let viewModel = AuthNumberViewModel(isNumberWithdraw: isNumberWithdraw)
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
    
    func makeArchiveView() -> ArchiveView {
        let viewModel = ArchiveViewModel()
        let view = ArchiveView(viewModel: viewModel)
        return view
    }
    
    func makePostView(with posts: [PostData], for postType: PostType) -> PostView {
        let viewModel = PostViewModel(posts: posts)
        let view = PostView(viewModel: viewModel, postType: postType)
        return view
    }
}

