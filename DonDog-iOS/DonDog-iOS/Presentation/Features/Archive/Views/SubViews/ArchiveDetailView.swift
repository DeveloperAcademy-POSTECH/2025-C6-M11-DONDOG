//
//  ArchiveDetailView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/16/25.
//

import SwiftUI

struct ArchiveDetailView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ArchiveDetailViewModel
    
    @State private var showDeleteMenu = false
    @State private var showDeleteAlert = false
    @State private var currentIndex: Int = 0
    @State private var scrollID: Int? = 0
    
    private var titleString: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.timeZone = TimeZone(identifier: "Asia/Seoul")
        fmt.dateFormat = "MM월 dd일"
        return fmt.string(from: viewModel.date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // CustomNavigationBar
            CustomNavigationBar(
                leadingType:
                        .back(
                            action: { coordinator.pop() }
                        ),
                centerType:
                        .title(title: titleString),
                trailingType: .menu(items: [
                    CustomNavMenuItem("삭제", role: .destructive) {
                        showDeleteAlert = true
                    },
                ]),
                navigationColor: .black
            )
            .padding(.horizontal, 20)
            
            // 인디케이터
            CustomPageIndicator(
                currentIndex: min(currentIndex + 1, max(viewModel.posts.count, 1)),
                totalCount: max(viewModel.posts.count, 1),
                backgroundColor: .ddGray100,
                textColor: .ddGray500
            )
            .padding(.vertical, 4)
            
            // 캐러셀
            TabView(selection: $currentIndex) {
                ForEach(Array(viewModel.posts.enumerated()), id: \.offset) { idx, post in
                    DetailContentContainer(post: post)
                        .tag(idx)
                }
            }
            .frame(maxWidth: .infinity)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: viewModel.posts.count) {
                currentIndex = 0
            }
        }
        .background(.ddWhite)
        .backHiddenSwipeEnabled()
        .alert("사진을 삭제하시겠어요?", isPresented: $showDeleteAlert) {
            Button("확인", role: .destructive) {
                // 삭제 로직
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("삭제한 사진은 되돌릴 수 없어요")
            
        }
    }
    
    private struct DetailContentContainer: View {
        let post: ArchivePost
        @State private var showingFront: Bool = true
        
        var body: some View {
            VStack(alignment: .center) {
                // 폴라로이드 프레임
                VStack {
                    // 사진
                    if let front = post.frontImageURL, let back = post.backImageURL {
                        ZStack {
                            AsyncPhoto(url: front)
                                .opacity(showingFront ? 1.0 : 0.0)
                                .rotation3DEffect(.degrees(showingFront ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                            
                            AsyncPhoto(url: back)
                                .opacity(showingFront ? 0.0 : 1.0)
                                .rotation3DEffect(.degrees(showingFront ? -180 : 0), axis: (x: 0, y: 1, z: 0))
                        }
                        .cornerRadius(8)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                showingFront.toggle()
                            }
                        }
                    } else if let front = post.frontImageURL {
                        AsyncPhoto(url: front)
                    } else if let back = post.backImageURL {
                        AsyncPhoto(url: back)
                    }
                    // CaptionContainer
                    VStack {
                        VStack {
                            if let cap = post.caption, !cap.isEmpty {
                                Text(cap)
                                    .font(.polaroidCaptionRegular20)
                                    .foregroundStyle(.ddGray1000)
                            } else {
                                Text(" ")
                                    .hidden()
                            }
                        }
                        .frame(height: 27) // 캡션이 없어도 높이 고정되게
                        
                        HStack(spacing: 4) {
                            if let author = post.authorName, !author.isEmpty {
                                Text(author)
                                    .foregroundStyle(.ddGray600)
                            }
                            Text(relativeTimeString(from: post.createdAt))
                                .foregroundStyle(.ddGray500)
                        }
                        .font(.captionRegular13)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                }
                .shadow(color: .ddBlack.opacity(0.05), radius: 2.5, x: 0, y: 3)
                
                // 댓글
                Spacer()
            }
        }
        
        private func relativeTimeString(from date: Date) -> String {
            let now = Date()
            let diff = now.timeIntervalSince(date)
            
            let seconds = Int(diff)
            let minutes = seconds / 60
            let hours = minutes / 60
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
            formatter.dateFormat = "HH:mm" // 하루 이상 지나면 시간만 표시
            
            switch seconds {
            case 0..<60:
                return "지금"
            case 60..<3600:
                return "\(minutes)분 전"
            case 3600..<(3600 * 24):
                return "\(hours)시간 전"
            default:
                return formatter.string(from: date)
            }
        }
        
        private struct AsyncPhoto: View {
            let url: URL
            var body: some View {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(3.0/4.0, contentMode: .fit)
                            .clipped()
                            .cornerRadius(10)
                            .transition(.opacity)
                    case .failure:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ddGray600)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(3.0/4.0, contentMode: .fit)
                            .overlay(Image(systemName: "photo").opacity(0.7))
                    case .empty:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ddGray600.opacity(0.08))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(3.0/4.0, contentMode: .fit)
                            .overlay(ProgressView())
                    @unknown default:
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .aspectRatio(3.0/4.0, contentMode: .fit)
                    }
                }
            }
        }
    }
}
