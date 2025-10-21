//
//  TextStrokeUtils.swift
//  DonDog-iOS
//
//  Created by Changjae Mun on 10/20/25.
//
import SwiftUI
import UIKit

struct StrokeText: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    let strokeColor: UIColor
    let strokeWidth: CGFloat
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        let attributes: [NSAttributedString.Key: Any] = [
            .strokeColor: strokeColor,
            .strokeWidth: strokeWidth,
            .font: font,
            .foregroundColor: textColor
        ]
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
        label.sizeToFit()
        label.textAlignment = .center
        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {
        let attributes: [NSAttributedString.Key: Any] = [
            .strokeColor: strokeColor,
            .strokeWidth: strokeWidth,
            .font: font,
            .foregroundColor: textColor
        ]
        uiView.attributedText = NSAttributedString(string: text, attributes: attributes)
        uiView.textAlignment = .center
        uiView.sizeToFit()
    }
}

struct StrokeTextView: View {
    let text: String
    let textColor: Color
    let fontName: String
    let fontSize: CGFloat
    let strokeColor: Color
    let strokeWidth: CGFloat
    
    var body: some View {
        StrokeText(
            text: text,
            font: UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize),
            textColor: UIColor(textColor),
            strokeColor: UIColor(strokeColor),
            strokeWidth: strokeWidth
        )
    }
}
