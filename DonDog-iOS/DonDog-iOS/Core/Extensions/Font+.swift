//
//  Font+.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/10/25.
//

import SwiftUI

enum FontName: String {
    case pretendardBold = "Pretendard-Bold"
    case pretendardSemiBold = "Pretendard-SemiBold"
    case pretendardMedium = "Pretendard-Medium"
    case pretendardRegular = "Pretendard-Regular"
    case sejongGeulggot = "SejongGeulggot"
}

extension Font {
    // MARK: - Title
    static var titleBold24: Font = .custom(FontName.pretendardBold.rawValue, size: 24)
    static var titleBold20: Font = .custom(FontName.pretendardBold.rawValue, size: 20)
    static var titleBold18: Font = .custom(FontName.pretendardBold.rawValue, size: 18)

    // MARK: - Subtitle
    static var subtitleMedium20: Font = .custom(FontName.pretendardMedium.rawValue, size: 20)
    static var subtitleMedium18: Font = .custom(FontName.pretendardMedium.rawValue, size: 18)
    static var subtitleSemiBold16: Font = .custom(FontName.pretendardSemiBold.rawValue, size: 16)

    // MARK: - Body
    static var bodyRegular18: Font = .custom(FontName.pretendardRegular.rawValue, size: 18)
    static var bodyMedium16: Font = .custom(FontName.pretendardMedium.rawValue, size: 16)
    static var bodyRegular16: Font = .custom(FontName.pretendardRegular.rawValue, size: 16)

    // MARK: - Caption
    static var captionMedium14: Font = .custom(FontName.pretendardMedium.rawValue, size: 14)
    static var captionRegular11: Font = .custom(FontName.pretendardRegular.rawValue, size: 11)
    static var captionRegular14: Font = .custom(FontName.pretendardRegular.rawValue, size: 14)
    static var captionRegular13: Font = .custom(FontName.pretendardRegular.rawValue, size: 13)
    
    // MARK: - Polaroid Caption
    static var polaroidCaptionRegular20: Font = .custom(FontName.sejongGeulggot.rawValue, size: 20)
    static var polaroidCaptionRegular16: Font = .custom(FontName.sejongGeulggot.rawValue, size: 16)
}
