//
//  StickerDecoView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/2/25.
//

import Combine
import SwiftUI
import UIKit

enum EntryRoute {
    case camera
    case picker
}

struct StickerConfirmView: View {
    @StateObject var viewModel: StickerConfirmViewModel
    let route: EntryRoute
    let onRetake: () -> Void
    let onComplete: () -> Void
    let onUploaded: (([String]) -> Void)?

    init(
        viewModel: StickerConfirmViewModel,
        route: EntryRoute = .picker,
        onRetake: @escaping () -> Void = {},
        onComplete: @escaping () -> Void = {},
        onUploaded: (([String]) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.route = route
        self.onRetake = onRetake
        self.onComplete = onComplete
        self.onUploaded = onUploaded
    }

    var body: some View {
        VStack {
            CustomNavigationBar(leadingType: .none, centerType: .none, trailingType: .close(action: { onComplete() }), navigationColor: .black)
            .padding(.horizontal, 16)
            
            if viewModel.image == nil || (viewModel.uploadError != nil) {
                Image(UserPairingStore.shared.myRole == "parent" ? "ParentEmptyView" : "ChildEmptyView")
                    .padding(.bottom, 16)
                
                Text("스티커 만들기를 실패했어요")
                    .foregroundStyle(Color.ppGray600)
                    .font(.bodyRegular16)
                
                Spacer()
                
                CustomButton(title: route == .camera ? "다시 촬영하기" : "사진 변경하기", style: .secondary, isEnable: true, action: {
                    onRetake() })
                    .padding(.horizontal, 21)
            } else {
                VStack {
                    Text("만들어진 스티커를 확인해 주세요!")
                        .font(.subtitleMedium18)
                        .padding(.vertical, 24)
                    
                    Spacer()
                    
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 360)
                            .clipped()
                            .padding(.bottom, 150)
                    }
                        
                    Spacer()
                    
                    HStack {
                        CustomButton(title: route == .camera ? "다시 찍기" : "사진 변경하기", style: .secondary, isEnable: true, action: { onRetake() })

                        Spacer()
                            .frame(maxWidth: 16)
                        
                        CustomButton(title: "스티커 저장", style: .primary, isEnable: !viewModel.isSaving, action: {
                            viewModel.isSaving = true
                            viewModel.uploadSticker { tags in
                                onUploaded?(tags)
                                onComplete()
                            }
                        }, isProgressView: viewModel.isSaving)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

#Preview("StickerConfirm - Picker") {
    let dummyImage = UIImage(systemName: "photo")!
    let viewModel = StickerConfirmViewModel(image: dummyImage)
    return StickerConfirmView(
        viewModel: viewModel,
        route: .picker,
        onRetake: { //
        },
        onComplete: { //
        }
    )
}
