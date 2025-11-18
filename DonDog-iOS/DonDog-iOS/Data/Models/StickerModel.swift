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
    case character = "픽픽캐릭터"
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

struct StickerStyleData {
    let title: String
    let outlineColor: Color
    let stickerDecoString: String
    
    static func style(forTitle title: String) -> StickerStyleData? {
        return dummy.first { $0.title == title }
    }
    
    static let dummy: [StickerStyleData] = [
        // 애정
        .init(title: "젤 사랑해", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        .init(title: "넘 예쁘다", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        .init(title: "보고 싶어", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        .init(title: "안전귀가!", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        .init(title: "밥이 보약", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        .init(title: "행운부적", outlineColor: .ddAffectionPink, stickerDecoString: "loveSticker"),
        
        // 걱정
        .init(title: "항상 네 편이야", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "덕분에 늘 든든해", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "날씨 짱인데", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "파이팅!", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "밥 먹을 시간", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "이불 밖은 위험해", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        .init(title: "건강이 최고", outlineColor: .ddWorryBlue, stickerDecoString: "sadSticker"),
        
        // 칭찬
        .init(title: "귀여워 죽겠어!", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "100점!", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "집에 언제 와?", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "집에 가고 싶어", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "멋지다", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "아프지 마!", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "무리하지 마!", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "나 보고 힘내!", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker"),
        .init(title: "잠이 보약", outlineColor: .ddPraiseYellow, stickerDecoString: "coolSticker")
    ]
}
