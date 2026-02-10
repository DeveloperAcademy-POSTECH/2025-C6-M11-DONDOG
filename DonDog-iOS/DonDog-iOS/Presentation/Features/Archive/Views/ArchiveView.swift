//
// ArchiveView.swift
// DonDog-iOS
//
// Created by 조유진 on 10/11/25.

import SwiftUI
import Kingfisher

enum ArchiveSegment: String, CaseIterable, Identifiable {
    case partnerArchive = "가족 사진"
    case myArchive = "내 사진"
    
    var id: String { self.rawValue }
}

struct ArchiveView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = ArchiveViewModel()
    @State private var showToastView = false
    
    private let grid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack {
                    CustomNavigationBar(
                        leadingType: .back(action: { coordinator.pop() }),
                        centerType: .title(title: "보관함"),
                        trailingType: .setting(action: { coordinator.push(.setting) }),
                        navigationColor: .black
                    )
                    .padding(.horizontal, 20)
                    
                    // Month 이동
                    HStack(spacing: 16) {
                        Spacer()
                        
                        if viewModel.hasPreviousDisplayMonth {
                            Button {
                                viewModel.goToPreviousMonth()
                            } label: {
                                Image("ArchiveLeftButton")
                                    .frame(width: 16, height: 16)
                            }
                            .padding(.horizontal, 10)
                            .disabled(!viewModel.hasPreviousDisplayMonth)
                        }
                    
                        if !viewModel.displayMonths.isEmpty {
                            Text(DateUtils.string(from: viewModel.displayMonths[viewModel.currentMonthIndex].date, format: .month))
                                .font(.subtitleMedium20)
                        } else {
                            Text(DateUtils.string(from: Date(), format: .month))
                                .font(.subtitleMedium20)
                        }
                        
                        if viewModel.hasNextDisplayMonth {
                            Button {
                                viewModel.goToNextMonth()
                            } label: {
                                Image("ArchiveRightButton")
                                    .frame(width: 16, height: 16)
                            }
                            .padding(.horizontal, 10)
                            .disabled(!viewModel.hasNextDisplayMonth)
                        }
                        
                        Spacer()
                    }
                    .foregroundStyle(.ppBlack)
                    .padding(.vertical, 23)
                    .background(.ppGray200)
                }
                
                ZStack {
                    // 사진 0장일 때 예외처리
                    if !viewModel.isLoading {
                        if !viewModel.displayMonths.isEmpty {
                            let month = viewModel.displayMonths[viewModel.currentMonthIndex]
                            if month.days.isEmpty {
                                VStack(spacing: 16) {
                                    Spacer()
                                    Image("ArchiveEmptyView")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 160, height: 118)
                                    Text(
                                        viewModel.isCurrentMonthDisplayed
                                        ? "아직 사진이 없어요\n첫 게시물을 올려 볼까요?"
                                        : "기록이 없어요"
                                    )
                                    .multilineTextAlignment(.center)
                                    .font(.bodyMedium16)
                                    .foregroundStyle(.ppGray500)
                                }
                                Spacer()
                            } else {
                                ScrollView {
                                    VStack {
                                        LazyVGrid(columns: grid, spacing: 4) {
                                            ForEach(month.days) { day in
                                                ArchivePostContainer(url: day.thumbnailURL, day: day.day, date: day.date, isBlurred: viewModel.isPostBlurred(for: day))
                                                    .onTapGesture {
                                                        if !viewModel.isPostBlurred(for: day) {
                                                            viewModel.moveToPost(day: day)
                                                        } else {
                                                            showToastView = true
                                                        }
                                                    }
                                                    .hapticFeedback(.medium)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.top, 20)
                                    }
                                }
                            }
                        } else {
                            VStack(spacing: 16) {
                                Spacer()
                                Image("ArchiveEmptyView")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 160, height: 118)
                                Text("아직 사진이 없어요\n첫 게시물을 올려 볼까요?")
                                    .multilineTextAlignment(.center)
                                    .font(.bodyMedium16)
                                    .foregroundStyle(.ppGray500)
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
            
            if viewModel.isLoading {
                VStack(alignment: .center, spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.ppPrime)
                    Text("로딩중...")
                        .font(.bodyMedium16)
                        .foregroundStyle(.ppPrime)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ppWhite)
            }
            
            if showToastView {
                VStack {
                    Spacer()
                    ToastView(toastText: "게시물을 올린지 3일이 지났어요!")
                        .padding(.bottom, 101)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                withAnimation { showToastView = false }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).animation(.spring()),
                            removal: .opacity.animation(.easeOut(duration: 0.7))
                        ))
                }
            }
        }
        .background(.ppWhite)
        .backHiddenSwipeEnabled()
        .task {
            viewModel.attach(coordinator: coordinator)
            await viewModel.updateMonthlyArchives()
        }
        .safeAreaInset(edge: .bottom) {
            CustomSegmentedControl(
                items: ArchiveSegment.allCases,
                selectedItem: $viewModel.selectedAuthorType,
                titleProvider: { $0.rawValue }
            )
            .padding(.bottom, 8)
        }
    }
}

struct ArchivePostContainer: View {
    let url: URL
    let day: Int
    let date: Date
    let isBlurred: Bool
    
    @State private var isFailed = false
    
    var body: some View {
        ZStack(alignment: .center) {
            KFImage.url(url)
                .onProgress { _, _ in
                    isFailed = false
                }
                .onSuccess { _ in
                    isFailed = false
                }
                .onFailure { _ in
                    isFailed = true
                }
                .placeholder {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.ppGray200)
                        .frame(width: 72, height: 96)
                }
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 96)
                .transition(.opacity)
                .blur(radius: isBlurred ? 4 : 0)
                .cornerRadius(2)
                .clipped()
                .overlay(
                    Group {
                        if isBlurred {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.ppBlack.opacity(0.3))
                                .overlay {
                                    VStack {
                                        Text("\(day)일")
                                            .font(.subtitleSemiBold16)
                                            .foregroundStyle(.ddWhite)
                                        Image(systemName: DateUtils.isATime(date: date) ? "sun.max.fill" : "moon.fill")
                                            .font(.bodyMedium16)
                                            .foregroundStyle(.ddWhite)
                                    }
                                }
                        } else if isFailed {
                            ZStack {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.ppGray600)
                                    .overlay(Image(systemName: "exclamationmark.triangle").foregroundStyle(.white))
                                    .frame(width: 72, height: 96)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.ppBlack.opacity(0.3))
                                .overlay {
                                    VStack(alignment: .center) {
                                        Text("\(day)일")
                                            .font(.subtitleSemiBold16)
                                            .foregroundStyle(.ddWhite)
                                        
                                        Image(systemName: DateUtils.isATime(date: date) ? "sun.max.fill" : "moon.fill")
                                            .font(.bodyMedium16)
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                    }
                )
        }
    }
}
