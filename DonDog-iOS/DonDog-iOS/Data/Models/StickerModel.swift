//
//  StickerModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/2/25.
//

import FirebaseFirestore
import Foundation
import SwiftUI

/// 서버 통신용
struct StickerData: Codable, Identifiable {
    @DocumentID var id: String?
    let authorUid: String
    let stickerURL: String
    let authorRole: String
    let emotionTags: [String]
    let createdAt: Date
}

/// 로컬 UI용
struct StickerItem: Identifiable, Hashable {
    let id = UUID()
    let title: String // 세부 감정 문구 (예: "보고싶다")
    var image: UIImage? // 누끼 완료된 스티커 이미지
}

enum StickerCategory: String, CaseIterable, Identifiable {
    case bigEmotion = "크게표현"
    case character = "픽픽 캐릭터"
    case speechBubble = "말풍선"
    var id: String { rawValue }
}

struct StickerCategoryData {
    static func itemsByCategory(for role: String?) -> [StickerCategory: [StickerItem]] {
        let isParent = (role == "parent")
        var dict: [StickerCategory: [StickerItem]] = [:]
        
        dict[.bigEmotion] = [
            .init(title: "젤 사랑해", image: nil),
            .init(title: "넘 예쁘다", image: nil),
            .init(title: "보고 싶어", image: nil),
            .init(title: "안전귀가!", image: nil),
            .init(title: "밥이 보약", image: nil),
            .init(title: "행운부적", image: nil)
        ]

        dict[.character] = [
            .init(
                title: isParent ? "항상 네 편이야" : "덕분에 늘 든든해",
                image: nil),
            .init(title: "날씨 짱인데", image: nil),
            .init(title: "파이팅!", image: nil),
            .init(title: "밥 먹을 시간", image: nil),
            .init(title: "이불 밖은 위험해", image: nil),
            .init(title: "건강이 최고", image: nil)
        ]

        dict[.speechBubble] = [
            .init(title: "귀여워 죽겠어!", image: nil),
            .init(title: "100점!", image: nil),
            .init(
                title: isParent ? "집에 언제 와?" : "집에 가고 싶어",
                image: nil),
            .init(title: "아프지 마!", image: nil),
            .init(
                title: isParent ? "무리하지 마!" : "나 보고 힘내!",
                image: nil),
            .init(title: "잠이 보약", image: nil)
        ]
        
        return dict
    }
}

extension Color {
    static let ddAffectionPink = Color(hex: "#FF91A4")
    static let ddWorryBlue = Color(hex: "#89CFF0")
    static let ddPraiseYellow = Color(hex: "#FFE873")
    static let ddHumorGreen = Color(hex: "#A4DE02")
    static let ddDailyOrange = Color(hex: "#FFB347")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct StickerLayout {
    let outlinedSize: CGSize /// 누끼+보더된 사용자 사진의 스케일
    let outlinedOffset: CGSize /// 누끼+보더된 사용자 사진의 위치 (상하좌우)
    let outlinedOnTop: Bool = true/// 누끼+보더 사진과 꾸밈 이미지 중 어느 것이 먼저인지 (기본값 true = 사용자 사진이 상단)

    /// 기본 레이아웃: 360x300 캔버스, 아웃라인 중앙, 데코 전체 배경
    static let `default` = StickerLayout(
        outlinedSize: CGSize(width: 100, height: 100),
        outlinedOffset: .zero
    )
}

struct StickerStyleData {
    let title: String
    let role: String?
    let stickerDecoBackground: String
    let layout: StickerLayout
    
    static func style(forTitle title: String, role: String?) -> StickerStyleData? {
        if let role = role, let matched = styles.first(where: { $0.title == title && $0.role == role }) {
            return matched
        }
        return styles.first(where: { $0.title == title && $0.role == nil })
    }
    
    static let styles: [StickerStyleData] = [
        // 크게표현
        .init(title: "젤 사랑해", role: nil, stickerDecoBackground: "big_1",
              layout: StickerLayout(outlinedSize: CGSize(width: 90, height: 120),
                                    outlinedOffset: CGSize(width: 0, height: -4))),
        .init(title: "넘 예쁘다", role: nil, stickerDecoBackground: "big_2", layout: .default),
        .init(title: "보고 싶어", role: nil, stickerDecoBackground: "big_3", layout: .default),
        .init(title: "안전귀가!", role: nil, stickerDecoBackground: "big_4", layout: .default),
        .init(title: "밥이 보약", role: nil, stickerDecoBackground: "big_5", layout: .default),
        .init(title: "행운부적", role: nil, stickerDecoBackground: "big_6", layout: .default),
        
        // 픽픽 캐릭터
        .init(title: "항상 네 편이야", role: "parent", stickerDecoBackground: "char_1_parent", layout: .default),
        .init(title: "덕분에 늘 든든해", role: "child", stickerDecoBackground: "char_1_child", layout: .default),
        .init(title: "날씨 짱인데", role: nil, stickerDecoBackground: "char_2", layout: .default),
        .init(title: "파이팅!", role: "parent", stickerDecoBackground: "char_3_parent", layout: .default),
        .init(title: "파이팅!", role: "child", stickerDecoBackground: "char_3_child", layout: .default),
        .init(title: "밥 먹을 시간", role: "parent", stickerDecoBackground: "char_4_parent", layout: .default),
        .init(title: "밥 먹을 시간", role: "child", stickerDecoBackground: "char_4_child", layout: .default),
        .init(title: "이불 밖은 위험해", role: "parent", stickerDecoBackground: "char_5_parent", layout: .default),
        .init(title: "이불 밖은 위험해", role: "child", stickerDecoBackground: "char_5_child", layout: .default),
        .init(title: "건강이 최고", role: "parent", stickerDecoBackground: "char_6_parent", layout: .default),
        .init(title: "건강이 최고", role: "child", stickerDecoBackground: "char_6_child", layout: .default),
        
        //말풍선
        .init(title: "귀여워 죽겠어!", role: nil, stickerDecoBackground: "bubble_1", layout: .default),
        .init(title: "100점!", role: nil, stickerDecoBackground: "bubble_2", layout: .default),
        .init(title: "집에 언제 와?", role: "parent", stickerDecoBackground: "bubble_3_parent", layout: .default),
        .init(title: "집에 가고 싶어", role: "child", stickerDecoBackground: "bubble_3_child", layout: .default),
        .init(title: "아프지 마!", role: nil, stickerDecoBackground: "bubble_4", layout: .default),
        .init(title: "무리하지 마!", role: "parent", stickerDecoBackground: "bubble_5_parent", layout: .default),
        .init(title: "나 보고 힘내!", role: "child", stickerDecoBackground: "bubble_5_child", layout: .default),
        .init(title: "잠이 보약", role: nil, stickerDecoBackground: "bubble_6", layout: .default)
    ]
}
