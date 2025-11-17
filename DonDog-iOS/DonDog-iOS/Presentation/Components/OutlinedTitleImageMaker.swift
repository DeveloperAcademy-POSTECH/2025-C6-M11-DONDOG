//
//  OutlinedTitleImageMaker.swift
//  Saboteur
//
//  Created by 이주현 on 11/12/25.
//

import SwiftUI
import UIKit

import UIKit

// MARK: - Component: OutlinedTitleImageMaker (StrokedLabel 스타일)
public final class OutlinedTitleImageMaker {
    @discardableResult
    public static func render(
        text: String,
        font: UIFont,
        fill: UIColor,
        stroke: UIColor,
        strokeWidth: CGFloat,
        kerning: CGFloat = 0,
        maxWidth: CGFloat
    ) -> UIImage {

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = UIScreen.main.scale

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byClipping

        // 채움 전용 (검정색)
        var fillAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: fill,
            .paragraphStyle: paragraph
        ]
        if kerning != 0 { fillAttrs[.kern] = kerning }
        let fillAttr = NSAttributedString(string: text, attributes: fillAttrs)

        // 색깔 윤곽선
        var outlineAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .strokeColor: stroke,
            .strokeWidth: abs(strokeWidth) * 2.0,
            .foregroundColor: UIColor.clear,
            .paragraphStyle: paragraph
        ]
        if kerning != 0 { outlineAttrs[.kern] = kerning }
        let outlineAttr = NSAttributedString(string: text, attributes: outlineAttrs)

        // 한 줄 텍스트 크기 측정
        let rawSize = (text as NSString).size(withAttributes: fillAttrs)

        let pad = ceil(max(2, strokeWidth * 2))
        let baseSize = CGSize(width: ceil(rawSize.width) + pad * 2, height: ceil(rawSize.height) + pad * 2)

        let baseRenderer = UIGraphicsImageRenderer(size: baseSize, format: format)
        let baseImage = baseRenderer.image { _ in
            UIColor.clear.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: baseSize)).fill()
            let drawPoint = CGPoint(x: pad, y: pad)

            // 1) 바깥 윤곽선
            outlineAttr.draw(at: drawPoint)

            // 2) 내부 채움(검정색) 오버드로우로 두껍게
            let offsets: [CGPoint] = [
                .zero,
                CGPoint(x: 0.6, y: 0),
                CGPoint(x: -0.6, y: 0),
                CGPoint(x: 0, y: 0.6),
                CGPoint(x: 0, y: -0.6),
                CGPoint(x: 0.45, y: 0.45),
                CGPoint(x: -0.45, y: 0.45),
                CGPoint(x: 0.45, y: -0.45),
                CGPoint(x: -0.45, y: -0.45)
            ]
            for o in offsets {
                fillAttr.draw(at: CGPoint(x: drawPoint.x + o.x, y: drawPoint.y + o.y))
            }
        }

        let scale = min(1.0, maxWidth / baseImage.size.width)
        if scale >= 1.0 { return baseImage }
        let targetSize = CGSize(width: floor(baseImage.size.width * scale),
                                height: floor(baseImage.size.height * scale))
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let scaled = renderer.image { _ in
            baseImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return scaled
    }
}
