//
//  FeedView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Kingfisher
import SwiftUI
import UIKit

struct FeedView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: FeedViewModel
    
    @State var showCameraView: Bool = false
    @State private var isRefreshing = false
    @State private var isFrontImageOnTop = true
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var isSelectingSticker = false
    @State private var showStickerSheet = false
    @State private var showToastView = false
    @State private var toastWorkItem: DispatchWorkItem?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if viewModel.connectUserInfo.isConnected == false {
                        Button {
                            coordinator.push(.setting)
                        } label: {
                            Image(systemName: "gear")
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color.ddPrimaryBlue)
                                .padding(.vertical, 8)
                                .padding(.trailing, 20)
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    if !viewModel.displayablePosts.isEmpty && !viewModel.isUploading {
                        Text("\(viewModel.currentPostIndex + 1)/\(viewModel.displayablePosts.count)")
                            .font(.captionRegular13)
                            .foregroundStyle(.ddGray600)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background {
                                Rectangle()
                                    .foregroundStyle(.ddGray100)
                                    .cornerRadius(120)
                            }
                    } else {
                        Text("")
                            .font(.captionRegular13)
                            .foregroundStyle(.ddGray600)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                    }
                    Spacer()
                }
                .padding(.top, 24)
                
                if viewModel.isLoading || viewModel.isUploading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.ddPrimaryBlue)
                        Text("로딩중...")
                            .font(.bodyMedium16)
                            .foregroundStyle(.ddPrimaryBlue)
                    }
                    .padding(.top, 280)
                } else if viewModel.connectUserInfo.isConnected == false {
                    VStack {
                        Spacer()
                        Image(systemName: "person.fill.xmark")
                            .foregroundStyle(Color.ddSecondaryBlue)
                            .font(.system(size: 40))
                        Text("아직 가족과 연결되지 않았어요\n아래 버튼으로 가족을 초대할 수 있어요")
                            .font(.bodyRegular16)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.ddSecondaryBlue)
                            .padding(10)
                        Button {
                            coordinator.inviteShowSentHint = false
                            coordinator.push(.invite)
                        } label: {
                            HStack(alignment: .center, spacing: 10) {
                                Text("가족 초대하기")
                                    .foregroundStyle(Color.ddGray100)
                                    .font(.captionRegular14)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.ddPrimaryBlue)
                            .cornerRadius(999)
                        }
                        Spacer()
                    }
                } else if !viewModel.displayablePosts.isEmpty {
                    ZStack {
                        TabView(selection: $viewModel.currentPostIndex) {
                            ForEach(Array(viewModel.displayablePosts.indices), id: \.self) { index in
                                let displayablePost = viewModel.displayablePosts[index]
                                if let front = displayablePost.frontImageURL, let back = displayablePost.backImageURL {
                                    HStack {
                                        Spacer()
                                        PolaroidSetView(
                                            frontImage: .url(front),
                                            backImage: .url(back),
                                            name: displayablePost.name,
                                            createdAt: DateUtils.relativeTimeString(from: displayablePost.createdAt),
                                            caption: displayablePost.caption,
                                            stickers: viewModel.stickerCache[viewModel.currentPost?.postId ?? ""],
                                            selectedStickerType: displayablePost.stickerType,
                                            isMyPost: displayablePost.isMyPost
                                        )
                                        .allowsHitTesting(true)
                                        .scaleEffect(index == viewModel.currentPostIndex ? 1.0 : 0.95)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentPostIndex)
                                    }
                                    .padding(.top, 93)
                                    .padding(.trailing, 26)
                                    .tag(index)
                                }
                            }
                        }
                        .frame(height: 520)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentPostIndex)
                        .task(id: viewModel.currentPostIndex) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.updateCurrentPost(at: viewModel.currentPostIndex)
                            }
                        }
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    guard let post = viewModel.currentPost else {
                                        print("현재 post가 없습니다.")
                                        return
                                    }
                                    coordinator.push(.post(post: post))
                                } label: {
                                    ZStack {
                                        Image("DetailViewButton")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 109)
                                        Text("댓글 쓰기...")
                                            .font(.bodyMedium16)
                                            .foregroundStyle(.ddGray500)
                                            .padding(.bottom, 10)
                                    }.padding(.trailing, 20)
                                }
                            }
                            .hapticFeedback(.medium)
                            Spacer()
                        }
                        .padding(.top, 23)
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .foregroundStyle(.ddSecondaryBlue)
                            .scaledToFit()
                            .frame(width: 60)
                        Text("아직 사진이 없어요\n오늘의 첫 게시물을 올려 볼까요?")
                            .multilineTextAlignment(.center)
                            .font(.bodyMedium16)
                            .foregroundStyle(.ddSecondaryBlue)
                    }
                    .padding(.top, 280)
                }
                Spacer()
                if viewModel.connectUserInfo.isConnected == true {
                    HStack {
                        Spacer()
                        Button {
                            coordinator.push(.archive)
                        } label: {
                            VStack(spacing: 2) {
                                Image("CalendarButton")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40)
                                    .foregroundStyle(.ddPrimaryBlue)
                                Text("보관함")
                                    .foregroundStyle(.ddPrimaryBlue)
                                    .font(.captionRegular14)
                            }
                        }
                        .hapticFeedback(.medium)
                        Spacer()
                        Button {
                            showCameraView = true
                        }label: {
                            Circle()
                                .foregroundColor(.ddWhite)
                                .frame(width: 64, height: 64)
                                .background {
                                    Circle()
                                        .foregroundColor(.ddPrimaryBlue)
                                        .frame(width: 72, height: 72)
                                }
                        }
                        .hapticFeedback(.medium)
                        Spacer()
                        Button {
                            if !viewModel.displayablePosts.isEmpty {
                                let currentPost = viewModel.displayablePosts[viewModel.currentPostIndex]
                                if !currentPost.isMyPost {
                                    showStickerSheet = true
                                } else {
                                    showToastView = true
                                }
                            }
                        } label: {
                            if !viewModel.displayablePosts.isEmpty {
                                VStack(spacing: 2) {
                                    Image(viewModel.displayablePosts[viewModel.currentPostIndex].isMyPost ?  "AddStickerButtonDisabled" : "AddStickerButtonAbled")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40)
                                    Text("스티커")
                                        .foregroundStyle(viewModel.displayablePosts[viewModel.currentPostIndex].isMyPost ? .ddGray500 : .ddPrimaryBlue)
                                        .font(.captionRegular14)
                                }
                            } else {
                                VStack(spacing: 2) {
                                    Image("AddStickerButtonDisabled")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40)
                                    Text("스티커")
                                        .foregroundStyle(.ddGray500)
                                        .font(.captionRegular14)
                                }
                            }
                        }
                        .hapticFeedback(.medium)
                        Spacer()
                    }.padding(.bottom, 22)
                }
            }
            if showToastView {
                VStack {
                    Spacer()
                    ToastView(toastText: "스티커는 상대방 게시물에만 붙일 수 있어요!")
                        .padding(.bottom, 114)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).animation(.spring()),
                            removal: .opacity.animation(.easeOut(duration: 0.7))
                        ))
                }
            }
        }
        .onAppear {
            if viewModel.connectUserInfo.isConnected && !viewModel.isUploading && !viewModel.isLoading {
                viewModel.loadTodayPosts()
            }
        }
        .background {
            LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .opacity(0.35)
        }
        .onChange(of: showToastView) { _, newValue in
            if newValue {
                toastWorkItem?.cancel()
                
                let workItem = DispatchWorkItem {
                    withAnimation {
                        showToastView = false
                    }
                }
                toastWorkItem = workItem
                
                // 2초 후 실행
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
            }
        }
        .fullScreenCover(isPresented: $showCameraView) {
            CameraViewContainer(
                cameraViewModel: cameraViewModel,
                feedViewModel: viewModel,
                isPresented: $showCameraView
            )
        }
        .sheet(isPresented: $showStickerSheet) {
            if viewModel.stickers != nil {
                let currentPost = viewModel.displayablePosts[viewModel.currentPostIndex]
                StickerSheetView(
                    initialSelectedType: StickerType(rawValue: currentPost.stickerType ?? ""),
                    stickers: viewModel.stickers ?? [:],
                    name: viewModel.currentUserName,
                    onSelect: { type in
                        if let type = type {
                            viewModel.type = type.rawValue
                            viewModel.updateStickerData()
                        } else {
                            viewModel.removeStickerData()
                        }
                    }
                )
                .presentationDetents([.height(392)])
                .presentationDragIndicator(.visible)
                .background(Color.ddWhite)
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Spacer()
                        Text("스티커를 만들 사진이 없어요")
                            .font(.subtitleSemiBold16)
                            .foregroundStyle(.ddGray600)
                        Text("첫 게시물을 올리면 감정 스티커를 붙일 수 있어요!")
                            .font(.captionRegular13)
                            .foregroundStyle(.ddGray500)
                        Button {
                            showStickerSheet = false
                        } label: {
                            ZStack {
                                Rectangle()
                                    .foregroundStyle(.ddPrimaryBlue)
                                    .frame(width: 112, height: 34)
                                    .cornerRadius(999)
                                HStack {
                                    Text("사진찍기")
                                        .font(.captionRegular13)
                                        .foregroundStyle(.ddGray100)
                                    Image(systemName: "camera")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(.ddGray100)
                                        .frame(height: 22)
                                }
                            }
                        }.padding(.top, 4)
                        Spacer()
                    }
                    Spacer()
                }
                .presentationDetents([.height(172)])
                .presentationDragIndicator(.visible)
                .background(Color.ddWhite)
                .ignoresSafeArea()
            }
        }
    }
}
