//
//  StickerModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/2/25.
//

import Foundation
import SwiftUI

enum StickerCategory: String, CaseIterable, Identifiable {
    case affection = "애정"
    case worry = "걱정"
    case praise = "칭찬"
    case humor = "유머"
    case daily = "일상"
    var id: String { rawValue }
}

struct StickerItem: Identifiable, Hashable {
    let id = UUID()
    let title: String // 세부 감정 문구 (예: "보고싶다")
    var image: UIImage? // 누끼 완료된 스티커 이미지 (없으면 + 버튼)
}

struct StickerCategoryData {
    static let itemsByCategory: [StickerCategory: [StickerItem]] = {
        var dict: [StickerCategory: [StickerItem]] = [:]
        
        dict[.affection] = [
            .init(title: "보고싶다", image: nil),
            .init(title: "사랑해", image: nil),
            .init(title: "안아줄게", image: nil),
            .init(title: "그리워", image: nil),
            .init(title: "빨리 만나자", image: nil),
            .init(title: "네 편이야", image: nil),
            .init(title: "고마워", image: nil)
        ]

        dict[.worry] = [
            .init(title: "괜찮아?", image: nil),
            .init(title: "밥 먹었어?", image: nil),
            .init(title: "무리하지 마", image: nil),
            .init(title: "아프지 마", image: nil),
            .init(title: "조심히 들어가", image: nil),
            .init(title: "연락 기다릴게", image: nil),
            .init(title: "천천히 해", image: nil),
            .init(title: "늦게까지 깨어있지 마", image: nil)
        ]

        dict[.praise] = [
            .init(title: "잘했어", image: nil),
            .init(title: "최고야", image: nil),
            .init(title: "대단해", image: nil),
            .init(title: "멋지다", image: nil),
            .init(title: "자랑스러워", image: nil),
            .init(title: "고생했어", image: nil),
            .init(title: "너답다", image: nil)
        ]

        dict[.humor] = [
            .init(title: "빵 터짐", image: nil),
            .init(title: "아재개그각", image: nil),
            .init(title: "오늘의 밈", image: nil),
            .init(title: "갸꿀잼", image: nil),
            .init(title: "드립 인정", image: nil),
            .init(title: "ㅋㅋㅋㅋ", image: nil),
            .init(title: "크크큭", image: nil)
        ]

        dict[.daily] = [
            .init(title: "오늘도 화이팅", image: nil),
            .init(title: "커피 한 잔", image: nil),
            .init(title: "퇴근!", image: nil),
            .init(title: "운동 가자", image: nil),
            .init(title: "산책 갈래", image: nil),
            .init(title: "날씨 좋네", image: nil),
            .init(title: "휴식 모드", image: nil)
        ]
        
        return dict
    }()
}
