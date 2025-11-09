//
//  PostView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import FirebaseFirestore
import SwiftUI

struct PostView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: PostViewModel
    
    @State private var showDeleteConfirmAlert: Bool = false
    @State private var showStickerSheet = false
    
    let postType: PostType
    
    var body: some View {
        let createdAt = viewModel.post.createdAt.dateValue()
        
        VStack {
            CustomNavigationBar(
                leadingType: .back(action: { coordinator.pop() }),
                centerType: .timeTitle(title: DateUtils.string(from: createdAt, format: .monthDay), timeImage: DateUtils.isATime(date: createdAt) ? "sun.max" : "moon.fill"),
                trailingType: viewModel.isMyPost ? .menu(items: [
                    CustomNavMenuItem("삭제하기", role: .destructive) {
                        showDeleteConfirmAlert = true
                    }
                ]) : .none,
                navigationColor: .black
            )
            .padding(.horizontal, 20)
            .backHiddenSwipeEnabled()
            .alert("삭제하시겠습니까?", isPresented: $showDeleteConfirmAlert) {
                Button("취소", role: .cancel) { }
                
                Button("삭제하기", role: .destructive) {
                    Task {
                        await viewModel.deletePost()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            coordinator.pop()
                        }
                    }
                }
            } message: {
                Text("게시물이 완전히 사라져요")
            }
            
            ZStack(alignment: .bottomTrailing) {
                PostContentsView(post: viewModel.post, isEditing: $showStickerSheet)
                
                if postType == .post {
                    Button {
                        showStickerSheet = true
                    } label: {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 90, height: 90)
                    }
                    .padding(.trailing, 14)
                }
            }
            .sheet(isPresented: $showStickerSheet) {
                StickerSheetView()
                    .presentationDetents([.height(270)])
                    .presentationDragIndicator(.hidden)
                    .background(Color.ddGray100.opacity(0.5))
            }
        }
        
        Spacer()
    }
}
