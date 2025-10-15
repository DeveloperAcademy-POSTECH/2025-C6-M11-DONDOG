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
    
    private struct ArchivePostContainer: View {
        let url: URL
        let day: Int
        
        var body: some View {
            ZStack(alignment: .center) {
                AsyncImage(url: url) { state in
                    switch state {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 75, height: 100)
                            .clipped()
                            .transition(.opacity)
                            .cornerRadius(8)
                            .overlay(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(.ddGray1000.opacity(0.3))
                                    
                                    Text("\(day)일")
                                        .font(.subtitleSemiBold16)
                                        .foregroundStyle(.ddWhite)
                                }
                            )
                        
                    case .failure:
                        Rectangle()
                            .fill(.ddGray600)
                            .cornerRadius(8)
                            .overlay(Image(systemName: "photo").opacity(0.7))
                            .frame(width: 75, height: 100)
                        
                    case .empty:
                        Rectangle()
                            .fill(.gray.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(ProgressView())
                            .frame(width: 75, height: 100)
                        
                    @unknown default:
                        Color.clear.frame(width: 75, height: 100)
                    }
                }
                
            }
        }
    }
    
    @ViewBuilder
    private func archivePlaceholder(height: CGFloat = 100) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: height)
            .cornerRadius(8)
            .overlay(
                Image(systemName: "photo")
                    .foregroundStyle(.ddWhite.opacity(0.7))
            )
    }
    
    private func monthTitle(year: Int, month: Int) -> String {
        "\(year)년 \(month)월"
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
                        VStack(alignment: .leading) {
                            Text("\(viewModel.partnerNickname)").bold()
                            + Text("님과 ")
                            + Text("\(viewModel.myNickname)").bold()
                            + Text("님만의 윙크가\n")
                            + Text("\(viewModel.totalPostCount)장").bold()
                            + Text(" 모였어요")
                        }
                        .font(.bodyRegular18)
                        .padding(.vertical, 8)
                        
                        Spacer()
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    ForEach(viewModel.archiveMonths) { month in
                        VStack(alignment: .leading) {
                            Text(monthTitle(year: month.year, month: month.month))
                                .font(.subtitleSemiBold16)
                                .padding(.vertical, 8)
                            
                            LazyVGrid(columns: grid, spacing: 8) {
                                ForEach(month.days) { day in
                                    Button {
                                        print("\(month.year).\(month.month).\(day.day) 디테일 뷰 / postId: \(day.postId)")
                                    } label: {
                                        ArchivePostContainer(url: day.thumbnailURL, day: day.day)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(
            LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .opacity(0.35)
        )
        .navigationBarBackButtonHidden(true)
    }
}
