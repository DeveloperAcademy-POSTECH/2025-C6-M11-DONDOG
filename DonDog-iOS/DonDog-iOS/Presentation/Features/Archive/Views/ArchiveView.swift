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
        VStack(spacing: 0) {
            CustomNavigationBar(
                leadingType:
                        .back(
                            action: {
                                coordinator.pop()
                            }
                        ),
                centerType:
                        .title(title: "아카이브"),
                trailingType:
                        .setting(
                            action: {
                                coordinator.push(.setting)
                            }
                        ),
                navigationColor: .black
            )
            
            ScrollView {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 0) {
                                Text(viewModel.partnerNickname).bold()
                                Text("님과 ")
                                Text(viewModel.myNickname).bold()
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
                    
                    ForEach(viewModel.archiveMonths) { month in
                        VStack(alignment: .leading) {
                            Text(String("\(month.year)년 \(month.month)월"))
                                .font(.subtitleSemiBold16)
                                .padding(.vertical, 8)
                            
                            LazyVGrid(columns: grid, spacing: 8) {
                                ForEach(month.days) { day in
                                    Button {
                                        moveDailyArchive(month: month, day: day)
                                    } label: {
                                        ArchivePostContainer(url: day.thumbnailURL, day: day.day)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(
            LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .opacity(0.35)
        )
        .navigationBarBackButtonHidden(true)
    }
    
    // 일자별 기록으로 이동, 버튼 내부 타입 체커 이슈로 함수로 분리
    func moveDailyArchive(month: ArchiveMonth, day: ArchiveDay) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let comp = DateComponents(
            year: month.year, month: month.month, day: day.day,
            hour: 0, minute: 0, second: 0
        )
        guard let selectedDate = cal.date(from: comp) else { return }

        let key = viewModel.dayKey(from: selectedDate)
        let initial = viewModel.dailyPosts[key] ?? []

        coordinator.push(
            .archiveDetail(roomId: viewModel.roomId, date: selectedDate, initialPosts: initial)
        )
    }
}

