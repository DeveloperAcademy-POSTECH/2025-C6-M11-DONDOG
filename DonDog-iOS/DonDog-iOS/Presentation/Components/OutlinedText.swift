//
//  OutlinedText.swift
//  DonDog-iOS
//
//  Created by Changjae Mun on 10/20/25.
//
import SwiftUI
import UIKit

struct OutlinedText: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    let outlineColor: UIColor
    let outlineWidth: CGFloat
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        let attributes: [NSAttributedString.Key: Any] = [
            .strokeColor: outlineColor,
            .strokeWidth: outlineWidth,
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
            .strokeColor: outlineColor,
            .strokeWidth: outlineWidth,
            .font: font,
            .foregroundColor: textColor
        ]
        uiView.attributedText = NSAttributedString(string: text, attributes: attributes)
        uiView.textAlignment = .center
        uiView.sizeToFit()
    }
}

struct OutlineTextView: View {
    let text: String
    let textColor: Color
    let fontName: String
    let fontSize: CGFloat
    let outlineColor: Color
    let outlineWidth: CGFloat
    
    var body: some View {
        OutlinedText(
            text: text,
            font: UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize),
            textColor: UIColor(textColor),
            outlineColor: UIColor(outlineColor),
            outlineWidth: outlineWidth
        )
    }
}
