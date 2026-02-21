//
//  PostContentsView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import FirebaseCore
import Kingfisher
import SwiftUI
import UIKit

struct PostContentsView: View {
    let post: PostData
    @Binding var isEditing: Bool
    @StateObject var viewModel: StickerViewModel
    @Binding var isFrontOrBack: Int
    @Binding var isZooming: Bool
    @Binding var isShowDetail: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $isFrontOrBack) {
                VStack(spacing: 0) {
                    GeometryReader {
                        let size = $0.size
                        ImageView(urlString: post.frontImageURL, isEditing: $isEditing, viewModel: viewModel, isZooming: $isZooming, isShowDetail: $isShowDetail, isFront: true)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: isShowDetail ? 0 : 15))
                            .pinchZoom(isZooming: $isZooming, isShowDetail: isShowDetail)
                    }
                    .frame(height: isShowDetail ? 524 : 470)
                }
                .tag(0)
                .padding(.horizontal, isShowDetail ? 0 : 20)
                
                VStack(spacing: 0) {
                    GeometryReader {
                        let size = $0.size
                        ImageView(urlString: post.backImageURL, isEditing: $isEditing, viewModel: viewModel, isZooming: $isZooming, isShowDetail: $isShowDetail, isFront: false)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: isShowDetail ? 0 : 15))
                            .pinchZoom(isZooming: $isZooming, isShowDetail: isShowDetail)
                    }
                    .frame(height: isShowDetail ? 524 : 470)
                }
                .tag(1)
                .padding(.horizontal, isShowDetail ? 0 : 20)
            }
            .tabViewStyle(.page(indexDisplayMode: isShowDetail ? .never : .never))
            .overlay {
                TabViewBounceDisabler()
                    .allowsHitTesting(false)
            }
            .frame(maxHeight: isShowDetail ? 524 : 470)
            
            if isShowDetail {
                HStack(spacing: 7) {
                    Circle()
                        .frame(width: 7, height: 7)
                        .foregroundStyle(isFrontOrBack == 0 ? .ppWhite : .ppWhite.opacity(0.3))
                    Circle()
                        .frame(width: 7, height: 7)
                        .foregroundStyle(isFrontOrBack == 1 ? .ppWhite : .ppWhite.opacity(0.3))
                }
                .padding(.top, 22)
            } else {
                HStack(spacing: 7) {
                    Circle()
                        .frame(width: 7, height: 7)
                        .foregroundStyle(isFrontOrBack == 0 ? .ppPrime : .ppPrime.opacity(0.3))
                    Circle()
                        .frame(width: 7, height: 7)
                        .foregroundStyle(isFrontOrBack == 1 ? .ppPrime : .ppPrime.opacity(0.3))
                }
                .padding(.top, 12)
            }
            
            VStack(spacing: 4) {
                Text(isShowDetail ? "" : post.caption)
                    .font(.bodyRegular16)
                    .foregroundStyle(.ppBlack)
                
                Text(isShowDetail ? "" : DateUtils.relativeTimeString(from: post.createdAt.dateValue()))
                    .font(.captionRegular13)
                    .foregroundStyle(.ppGray500)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.top, isShowDetail ? 44 : 70)
    }
}

private struct TabViewBounceDisabler: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = findPagingScrollView(from: uiView) else { return }
            scrollView.bounces = false
            scrollView.alwaysBounceHorizontal = false
            
            if let popGesture = findNavigationController(from: uiView)?.interactivePopGestureRecognizer {
                popGesture.isEnabled = true
                scrollView.panGestureRecognizer.require(toFail: popGesture)
            }
        }
    }
    
    private func findPagingScrollView(from view: UIView) -> UIScrollView? {
        var current: UIView? = view
        
        while let candidate = current {
            if let scrollView = searchPagingScrollView(in: candidate) {
                return scrollView
            }
            current = candidate.superview
        }
        
        return nil
    }
    
    private func searchPagingScrollView(in root: UIView) -> UIScrollView? {
        if let scrollView = root as? UIScrollView, scrollView.isPagingEnabled {
            return scrollView
        }
        
        for subview in root.subviews {
            if let scrollView = searchPagingScrollView(in: subview) {
                return scrollView
            }
        }
        
        return nil
    }
    
    private func findNavigationController(from view: UIView) -> UINavigationController? {
        var responder: UIResponder? = view
        
        while let current = responder {
            if let navigationController = current as? UINavigationController {
                return navigationController
            }
            
            if let viewController = current as? UIViewController {
                return viewController.navigationController
            }
            
            responder = current.next
        }
        
        return nil
    }
}
