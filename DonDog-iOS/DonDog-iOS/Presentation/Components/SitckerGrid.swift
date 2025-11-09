//
//  SitckerGrid.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/9/25.
//

import Kingfisher
import SwiftUI

struct StickerGrid: View {
    let items: [StickerItem]
       let remoteURLByItemID: [StickerItem.ID: URL]
       let loadingItemIDs: Set<StickerItem.ID>
       let columns: [GridItem]
       let rowSpacing: CGFloat
       @Binding var isCameraPresented: Bool
       var isStickerConfirmPresented: Binding<Bool>?
       let onItemAppear: (StickerItem.ID) -> Void
       let onItemTap: (StickerItem) -> Void
       let onPlusTap: (StickerItem) -> Void
       let onCameraDismiss: (StickerItem.ID) -> Void
       let onConfirmDismiss: ((StickerItem.ID) -> Void)?

       init(
           items: [StickerItem],
           remoteURLByItemID: [StickerItem.ID: URL],
           loadingItemIDs: Set<StickerItem.ID>,
           columns: [GridItem],
           rowSpacing: CGFloat = 16,
           isCameraPresented: Binding<Bool>,
           isStickerConfirmPresented: Binding<Bool>? = nil,
           onItemAppear: @escaping (StickerItem.ID) -> Void,
           onItemTap: @escaping (StickerItem) -> Void,
           onPlusTap: ((StickerItem) -> Void)? = nil,
           onCameraDismiss: @escaping (StickerItem.ID) -> Void,
           onConfirmDismiss: ((StickerItem.ID) -> Void)? = nil
       ) {
           self.items = items
           self.remoteURLByItemID = remoteURLByItemID
           self.loadingItemIDs = loadingItemIDs
           self.columns = columns
           self.rowSpacing = rowSpacing
           self._isCameraPresented = isCameraPresented
           self.isStickerConfirmPresented = isStickerConfirmPresented
           self.onItemAppear = onItemAppear
           self.onItemTap = onItemTap
           self.onPlusTap = onPlusTap ?? onItemTap
           self.onCameraDismiss = onCameraDismiss
           self.onConfirmDismiss = onConfirmDismiss
       }


    var body: some View {
        LazyVGrid(columns: columns, spacing: rowSpacing) {
            ForEach(items) { item in
                VStack {
                    if let url = remoteURLByItemID[item.id] {
                        KFImage(url)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                            .contentShape(Rectangle())
                            .onTapGesture { onItemTap(item) }
                    } else {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary, style: StrokeStyle(lineWidth: 3, dash: [15, 5]))
                                    .frame(width: 100, height: 100)
                                
                                if loadingItemIDs.contains(item.id) {
                                    EmptyView()
                                } else {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20))
                                        .contentShape(Rectangle())
                                }
                            }
                            
                            if remoteURLByItemID[item.id] == nil {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !loadingItemIDs.contains(item.id) {
                                onPlusTap(item)
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .task { onItemAppear(item.id) }
                .onChange(of: isCameraPresented) { _, presented in
                    if presented == false { onCameraDismiss(item.id) }
                }
                .background(
                    Group {
                        if let confirm = isStickerConfirmPresented, let onConfirmDismiss {
                            Color.clear.onChange(of: confirm.wrappedValue) { _, presented in
                                if presented == false { onConfirmDismiss(item.id) }
                            }
                        } else {
                            Color.clear
                        }
                    }
                )
            }
        }
    }
}

extension View {
    /// 카메라 촬영 플로우: 사진 찍기 버튼 탭 시 전면 카메라 화면을 fullScreenCover로 표시
    func cameraCaptureFlow(isPresented: Binding<Bool>, cameraVM: CameraViewModel) -> some View {
           self.modifier(CameraCoverModifier(isPresented: isPresented, cameraVM: cameraVM))
       }

    /// 기존 게시물 사진 선택 → 스티커 컨펌까지의 플로우를 하나의 modifier로 묶음
    func photoPickerStickerConfirmFlow(viewModel: SitckerCollectionViewModel) -> some View {
        self.modifier(PhotoPickerAndConfirmModifier(viewModel: viewModel))
    }
}

struct CameraCoverModifier: ViewModifier {
    @Binding var isPresented: Bool
    let cameraVM: CameraViewModel

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                CameraView(viewModel: cameraVM)
                    .ignoresSafeArea()
            }
    }
}

struct PhotoPickerAndConfirmModifier: ViewModifier {
    @ObservedObject var viewModel: SitckerCollectionViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.showPhotoPicker) {
                PhotoPickerView(viewModel: PhotoPickerViewModel()) { image in
                    viewModel.pickedImage = image
                    viewModel.showPhotoPicker = false
                    DispatchQueue.main.async {
                        viewModel.showStickerConfirm = true
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showStickerConfirm) {
                if let image = viewModel.pickedImage {
                    StickerConfirmView(
                        viewModel: StickerConfirmViewModel(
                            image: image,
                            onDone: { _ in
                                viewModel.showStickerConfirm = false
                            }
                        ),
                        route: .picker,
                        onRetake: {
                            viewModel.showStickerConfirm = false
                            DispatchQueue.main.async {
                                viewModel.showPhotoPicker = true
                            }
                        },
                        onClose: {
                            viewModel.showStickerConfirm = false
                        }
                    )
                }
            }
    }
}
