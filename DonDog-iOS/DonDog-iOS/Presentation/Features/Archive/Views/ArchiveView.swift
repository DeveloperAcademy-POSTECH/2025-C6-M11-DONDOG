//
// ArchiveView.swift
// DonDog-iOS
//
// Created by 조유진 on 10/11/25.

import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ArchiveViewModel
    
    private let grid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    @ViewBuilder
    private func archivePlaceholder(height: CGFloat = 100) -> some View {
        Rectangle()
            .fill(.ddGray600.opacity(0.3))
            .frame(height: height)
            .cornerRadius(8)
            .overlay(
                Image(systemName: "photo")
                    .foregroundStyle(.ddWhite.opacity(0.7))
            )
    }
    
    var body: some View {
        ZStack {
            VStack {
                CustomNavigationBar(
                    leadingType: .back(action: { coordinator.pop() }),
                    centerType: .title(title: "아카이브"),
                    trailingType: .setting(action: { coordinator.push(.setting) }),
                    navigationColor: .black
                )
                
                // 사진 0장일 때 예외처리
                if !viewModel.isLoading && viewModel.totalPostCount == 0 {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .foregroundStyle(.ddSecondaryBlue)
                            .scaledToFit()
                            .frame(width: 57, height: 48)
                        Text("아직 사진이 없어요\n지금 순간을 사진으로 남겨보세요")
                            .multilineTextAlignment(.center)
                            .font(.bodyMedium16)
                            .foregroundStyle(.ddSecondaryBlue)
                    }
                    
                    Spacer()
                } else {
                    ScrollView {
                        VStack {
                            if viewModel.totalPostCount > 0 {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        // 이름 없을 때 예외처리 추후 수정
                                        HStack(spacing: 0) {
                                            Text(viewModel.connectUserInfo.partnerName ?? "상대방").bold()
                                            Text("님과 ")
                                            Text(viewModel.connectUserInfo.myName ?? "나").bold()
                                            Text("님만의 추억이")
                                        }
                                        HStack(spacing: 0) {
                                            Text("\(viewModel.totalPostCount)개").bold()
                                            Text(" 모였어요")
                                        }
                                    }
                                    .font(.bodyRegular18)
                                    .padding(.vertical, 8)
                                    
                                    Spacer()
                                }
                                Divider().padding(.vertical, 8)
                            }
                            
                            ForEach(viewModel.archiveMonths) { month in
                                VStack(alignment: .leading) {
                                    Text(DateUtils.string(from: month.date, format: .yearMonth))
                                        .font(.subtitleSemiBold16)
                                        .padding(.vertical, 8)
                                    
                                    LazyVGrid(columns: grid, spacing: 8) {
                                        ForEach(month.days) { day in
                                            if viewModel.isLoading {
                                                archivePlaceholder(height: 100)
                                            } else {
                                                Button {
                                                    viewModel.moveDailyArchive(month: month, day: day)
                                                } label: {
                                                    ArchivePostContainer(url: day.thumbnailURL, day: day.day)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            
            if viewModel.isLoading {
                VStack(alignment: .center, spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.ddPrimaryBlue)
                    Text("로딩중...")
                        .font(.bodyMedium16)
                        .foregroundStyle(.ddPrimaryBlue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ddWhite)
                .background(
                    LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                        .opacity(0.35)
                )
            }
        }
        .padding(.horizontal, 20)
        .background(.ddWhite)
        .backHiddenSwipeEnabled()
        .task {
            viewModel.attach(coordinator: coordinator)
            await viewModel.fetchMonthlyArchives()
        }
    }
}
