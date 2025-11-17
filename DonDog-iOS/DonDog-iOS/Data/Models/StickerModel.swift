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
    let uid: String
    let url: String
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
    case affection = "크게표현"
    case worry = "픽픽캐릭터"
    case praise = "말풍선"
    var id: String { rawValue }
}

struct StickerCategoryData {
    static let itemsByCategory: [StickerCategory: [StickerItem]] = {
        var dict: [StickerCategory: [StickerItem]] = [:]
        
        dict[.affection] = [
            .init(title: "보고싶다!!!", image: nil),
            .init(title: "사랑해!!!", image: nil),
            .init(title: "안아줄게!!!", image: nil),
            .init(title: "그리워!!!", image: nil),
            .init(title: "얼른집가!!!", image: nil),
            .init(title: "네 편이야!!!", image: nil)
        ]

        dict[.worry] = [
            .init(title: "괜찮아?", image: nil),
            .init(title: "밥 먹었어?", image: nil),
            .init(title: "무리하지 마", image: nil),
            .init(title: "아프지 마", image: nil),
            .init(title: "조심히 들어가", image: nil),
            .init(title: "연락 기다릴게", image: nil)
        ]

        dict[.praise] = [
            .init(title: "잘했어", image: nil),
            .init(title: "최고야", image: nil),
            .init(title: "대단해", image: nil),
            .init(title: "멋지다", image: nil),
            .init(title: "자랑스러워", image: nil),
            .init(title: "고생했어", image: nil)
        ]
        
        return dict
    }()
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

struct StickerStyleData {
    let title: String
    let outlineColor: Color
    let stickerDecoString: String
    
    static func style(forTitle title: String) -> StickerStyleData? {
        return dummy.first { $0.title == title }
    }
    
    static let dummy: [StickerStyleData] = [
        // 애정
        .init(title: "보고싶다!!!", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        .init(title: "사랑해!!!", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        .init(title: "안아줄게!!!", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        .init(title: "그리워!!!", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        .init(title: "얼른집가!!!", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        .init(title: "네 편이야!!!", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        
        // 걱정
        .init(title: "괜찮아?", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "밥 먹었어?", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "무리하지 마", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "아프지 마", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "조심히 들어가", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "연락 기다릴게", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        
        // 칭찬
        .init(title: "잘했어", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "최고야", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "대단해", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "멋지다", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "자랑스러워", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "고생했어", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker")
    ]
}
