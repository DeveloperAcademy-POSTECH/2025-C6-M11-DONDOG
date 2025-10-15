//
//  CustomNavigationBar.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/11/25.
//

import SwiftUI

enum CustomNavigationBarLeadingType {
    case back(action: () -> Void)
    case none
}

enum CustomNavigationBarCenterType {
    case title(title: String)
    case none
}

enum CustomNavigationBarTrailingType {
    case close(action: () -> Void)
    case option(action: () -> Void)
    case setting(action: () -> Void)
    case none
}

enum CustomNavigationBarColor {
    case black
    case white
}

struct CustomNavigationBar: View {
    private let leadingType: CustomNavigationBarLeadingType
    private let centerType: CustomNavigationBarCenterType
    private let trailingType: CustomNavigationBarTrailingType
    private let navigationColor: CustomNavigationBarColor
    
    private var color: Color {
        switch navigationColor {
        case .black:
            return .ddBlack
        case .white:
            return .ddWhite
        }
    }
    
    public init(
        leadingType: CustomNavigationBarLeadingType,
        centerType: CustomNavigationBarCenterType,
        trailingType: CustomNavigationBarTrailingType,
        navigationColor: CustomNavigationBarColor
    ) {
        self.leadingType = leadingType
        self.centerType = centerType
        self.trailingType = trailingType
        self.navigationColor = navigationColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                navigationLeadingView()
                
                Spacer()
                
                navigationCenterView()
                
                Spacer()
                
                navigationTrailingView()
            }
            .foregroundStyle(color)
            .padding(.vertical, 11)
            .background(.clear)
        }
    }
    
    // MARK: - Leading View
    
    @ViewBuilder
    private func navigationLeadingView() -> some View {
        switch leadingType {
        case .back(let action):
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .font(.body)
                    .frame(width: 24, height: 24)
            }
        case .none:
            Spacer().frame(width: 24).opacity(0)
        }
    }
    
    // MARK: - Center Title View
    
    @ViewBuilder
    private func navigationCenterView() -> some View {
        switch centerType {
        case .title(let text):
            Text(text)
                .font(.titleBold18)
            
        case .none:
            EmptyView()
        }
    }
    
    // MARK: - Trailing View
    
    @ViewBuilder
    private func navigationTrailingView() -> some View {
        switch trailingType {
        case .close(let action):
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.body)
                    .frame(width: 24, height: 24)
            }
            
        case .option(let action):
            Button(action: action) {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .frame(width: 24, height: 24)
            }
            
        case .setting(let action):
            Button(action: action) {
                Image(systemName: "gear")
                    .font(.body)
            }
            .frame(width: 24, height: 24)
            
        case .none:
            Spacer().frame(width: 24).opacity(0)
        }
    }
}

#Preview {
    // 전화번호 입력, 인증번호 입력, 가족 연결
    CustomNavigationBar(leadingType: .back(action: {}), centerType: .title(title: "본인인증"), trailingType: .none, navigationColor: .black)
    
    // 프로필 설정, 가족 연결
    CustomNavigationBar(leadingType: .none, centerType: .title(title: "가족연결"), trailingType: .none, navigationColor: .black)
    
    // 게시물 상세
    CustomNavigationBar(leadingType: .back(action: {}), centerType: .title(title: "10월 14일"), trailingType: .option(action: {}), navigationColor: .black)
    
    // 카메라 상세 - 촬영
    CustomNavigationBar(leadingType: .back(action: {}), centerType: .none, trailingType: .option(action: {}), navigationColor: .black)
    
    // 카메라 상세 - 캡션
    CustomNavigationBar(leadingType: .none, centerType: .none, trailingType: .close(action: {}), navigationColor: .black)
    
    // 카메라 상세 - 캡션 - 화이트
    CustomNavigationBar(leadingType: .none, centerType: .none, trailingType: .close(action: {}), navigationColor: .white)
        .background(.black)
}
