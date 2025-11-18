//
//  CameraStickerConfirmView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/17/25.
//

import SwiftUI

struct CameraStickerConfirmView: View {
    @Binding var isVisible: Bool
    @State private var animate = false
    var color: Color = .ppPrime
    
    var body: some View {
        if isVisible {
            GeometryReader { proxy in
                ZStack {
                    // 딤 처리 + 상단 스티커 가이드 영역은 둥근 사각형으로 뚫린 마스크
                    StickerGuideMaskShape(
                        topOffset: proxy.safeAreaInsets.top + 60,
                        horizontalInset: 20,
                        holeHeight: 96
                    )
                    .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
                    .ignoresSafeArea()
                    .onTapGesture {
                        // 배경 탭으로도 닫고 싶다면 여기에 처리
                        isVisible = false
                    }
                    
                    VStack(spacing: 6) {
                        Spacer()
                            .frame(height: proxy.safeAreaInsets.top + 80)
                        // 위쪽 작은 점 + 퍼지는 효과
                        ZStack {
                            Circle()
                                .fill(Color.ppPrime.opacity(0.7))
                                .frame(width: 18, height: 18)
                                .scaleEffect(animate ? 2.0 : 1.0)
                                .opacity(animate ? 0.0 : 0.7)
                            
                            Circle()
                                .fill(Color.ppPrime)
                                .frame(width: 10, height: 10)
                        }
                        .onAppear {
                            withAnimation(
                                .easeOut(duration: 1.0)
                                    .repeatForever(autoreverses: false)
                            ) {
                                animate = true
                            }
                        }
                        
                        VStack(spacing: 0) {
                            VerticalDashedLine()
                                .stroke(
                                    color,
                                    style: StrokeStyle(
                                        lineWidth: 2,
                                        lineCap: .round,
                                        dash: [3, 6]
                                    )
                                )
                                .frame(width: 6, height: 30)
                            
                            Circle()
                                .frame(width: 7, height: 7)
                                .foregroundStyle(Color.ppPrime)
                        }
                        
                        Text("스티커에 어울리는 포즈를 준비해 주세요")
                            .font(.bodyMedium16)
                            .foregroundColor(Color.ppWhite)
                            .padding(.top, 8)
                        
                        Button {
                            isVisible = false
                        } label: {
                            Text("확인")
                                .foregroundStyle(Color.ppWhite)
                                .font(.bodyMedium16)
                                .padding(.vertical, 11)
                                .padding(.horizontal, 46)
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundStyle(Color.ppPrime)
                                }
                        }
                        .padding(.vertical, 8)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
    }
}

struct StickerGuideMaskShape: Shape {
    /// 상단 가이드 뷰(stickerGuideContainer)에 맞춰 뚫린 네모 영역을 만드는 마스크
    var topOffset: CGFloat
    var horizontalInset: CGFloat
    var holeHeight: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // 전체 화면
        path.addRect(rect)
        
        // 뚫릴 둥근 사각형 영역
        let holeRect = CGRect(
            x: horizontalInset,
            y: topOffset,
            width: rect.width - horizontalInset * 2,
            height: holeHeight
        )
        path.addRoundedRect(in: holeRect, cornerSize: CGSize(width: 20, height: 20))
        
        return path
    }
}

struct VerticalDashedLine: Shape {
    // 위에서 아래로 한 줄 그리기
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

extension Notification.Name {
    /// 스티커 카메라 모드일 때 SwiftUI 오버레이(CameraStickerConfirmView)를 보여주기 위한 노티 이름
    static let stickerCameraShouldShowConfirm = Notification.Name("stickerCameraShouldShowConfirm")
}

#Preview {
    CameraStickerConfirmView(isVisible: .constant(true))
}
