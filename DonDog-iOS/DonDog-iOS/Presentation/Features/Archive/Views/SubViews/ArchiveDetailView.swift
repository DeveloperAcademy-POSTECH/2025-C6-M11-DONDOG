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
}
