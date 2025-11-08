//
//  StickerDecoView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/2/25.
//

import Combine
import SwiftUI

enum EntryRoute {
    case camera
    case picker
}

struct StickerConfirmView: View {
    @StateObject var viewModel: StickerConfirmViewModel
    @Environment(\.dismiss) private var dismiss
    let route: EntryRoute
    let onRetake: () -> Void
    let onClose: () -> Void

    init(viewModel: StickerConfirmViewModel, route: EntryRoute = .picker, onRetake: @escaping () -> Void = {}, onClose: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.route = route
        self.onRetake = onRetake
        self.onClose = onClose
    }

    var body: some View {
        VStack {
            CustomNavigationBar(leadingType: .none, centerType: .none, trailingType: .close(action: { onClose() }), navigationColor: .black)
                .padding(.trailing, 16)
            
            Text("만들어진 스티커를 확인해 주세요")
            
            Spacer()
            
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipped()
            }
            
            Spacer()
            
            if let error = viewModel.uploadError, !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
            }
            
            HStack {
                Button {
                    onRetake()
                } label: {
                    HStack(spacing: 8) {
                        Text(route == .camera ? "다시 찍기" : "다시 고르기")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .border(Color.black, width: 1)
                }

                Spacer()
                
                Button {
                    viewModel.uploadSticker()
                } label: {
                    HStack(spacing: 8) {
                        Text("스티커 저장하기")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .border(Color.black, width: 1)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
