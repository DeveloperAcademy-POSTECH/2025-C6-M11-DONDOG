//
//  ProfileView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/4/25.
//

import SwiftUI

enum ProfileFormMode {
    case setup // 최초 프로필 생성 + 초대코드 생성/저장 + 라우팅(.invite)
    case edit // 설정 - 기존 프로필 수정
}

struct ProfileView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ProfileViewModel
    @StateObject private var keyboard = KeyboardResponder()

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(
                leadingType: viewModel.mode == .edit ? .back(action: { coordinator.pop() }) : .none,
                centerType: .title(title: "프로필 설정", timeImage: ""),
                trailingType: .none,
                navigationColor: .black
            )

            HStack {
                Text("부모님과 자녀 ")
                + Text("둘만의 소통")
                    .font(.titleBold20)
                + Text("을 위해\n")
                + Text("별명과 역할")
                    .font(.titleBold20)
                + Text("을 설정해 주세요")

                Spacer()
            }
            .font(.subtitleMedium20)
            .padding(.vertical, 32)

            HStack(spacing: 56) {
                ForEach(ProfileViewModel.Role.allCases, id: \.self) { role in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .strokeBorder(
                                    viewModel.selectedRole == role ? Color.ddPrimaryBlue : Color.ddGray100, lineWidth: 4
                                )
                                .frame(width: 120, height: 120)

                            Text(role.displayIcon)
                                .font(.custom(FontName.pretendardBold.rawValue, size: 48))
                        }
                        .contentShape(Circle())
                        .onTapGesture { viewModel.selectedRole = role }

                        Text(role.displayName)
                            .font(viewModel.selectedRole == role ? .titleBold18 : .bodyRegular18)
                            .foregroundStyle(viewModel.selectedRole == role ? Color.ddPrimaryBlue : Color.ddBlack)
                    }
                    .accessibilityLabel(Text(role.displayName))
                    .accessibilityAddTraits(viewModel.selectedRole == role ? .isSelected : [])
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 26)

            CustomTextField(
                title: nil,
                placeholder: "불리고 싶은 별명을 입력해 주세요",
                text: $viewModel.name,
                keyboard: .default,
                contentType: nil,
                errorMessage: viewModel.errorMessage,
                softMaxLength: 10
            )

            Spacer()

            CustomButton(
                title: viewModel.mode == .edit ? "저장" : "다음",
                isEnable: viewModel.isButtonEnabled,
                action: viewModel.save
            )
        }
        .padding(.horizontal, 20)
        .dismissKeyboard()
        .backHiddenSwipeEnabled()
        .task {
            viewModel.attach(coordinator: coordinator)
            await viewModel.onAppearIfNeeded()
        }
        .onChange(of: viewModel.saveCompleted) { _, newValue in
            if newValue, viewModel.mode == .edit {
                coordinator.pop()
            }
        }
    }
}
