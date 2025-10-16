//
//  UIImage+.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/17/25.
//

import UIKit

extension UIImage {

    func addBorder(thickness: CGFloat, color: UIColor) -> UIImage? {
        let scale = self.scale
        let canvas = CGSize(width: self.size.width + thickness * 2,
                           height: self.size.height + thickness * 2)
        let origin = CGPoint(x: thickness, y: thickness)
        
        // 1. 테두리만 생성
        guard let borderOnly = createBorderOnly(canvas: canvas, origin: origin, thickness: thickness, color: color) else {
            return nil
        }
        
        // 2. 테두리 변형 (180° 회전 + 좌우 반전)
        guard let rotated = borderOnly.rotate180(),
              let mirrored = rotated.flipHorizontally() else {
            return nil
        }
        
        // 3. 최종 합성
        return compositeFinalImage(border: mirrored, original: self, canvas: canvas, origin: origin)
    }
    
    // MARK: - Private Helper Methods
    
    /// 테두리만 생성하는 함수
    private func createBorderOnly(canvas: CGSize, origin: CGPoint, thickness: CGFloat, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(canvas, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let ctx = UIGraphicsGetCurrentContext(),
              let maskCG = self.cgImage else { return nil }
        
        ctx.setFillColor(color.cgColor)
        
        // 8방향으로 테두리 생성
        for angle in stride(from: CGFloat(0), to: CGFloat.pi * 2, by: CGFloat.pi / 4) {
            let dx = cos(angle) * thickness
            let dy = sin(angle) * thickness
            let rect = CGRect(origin: CGPoint(x: origin.x + dx, y: origin.y + dy),
                            size: self.size)
            
            ctx.saveGState()
            ctx.clip(to: rect, mask: maskCG)
            ctx.fill(rect)
            ctx.restoreGState()
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 180° 회전 함수
    private func rotate180() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        // 좌표계를 오른쪽-아래 모서리로 이동한 뒤 180º 회전
        ctx.translateBy(x: self.size.width, y: self.size.height)
        ctx.rotate(by: CGFloat.pi)
        
        self.draw(in: CGRect(origin: .zero, size: self.size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 좌우 반전 함수
    private func flipHorizontally() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        // x축 기준으로 좌우 뒤집기
        ctx.translateBy(x: self.size.width, y: 0)
        ctx.scaleBy(x: -1, y: 1)
        
        self.draw(in: CGRect(origin: .zero, size: self.size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 최종 합성 함수
    private func compositeFinalImage(border: UIImage, original: UIImage, canvas: CGSize, origin: CGPoint) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(canvas, false, original.scale)
        defer { UIGraphicsEndImageContext() }
        
        border.draw(at: .zero) // 변환된 테두리
        original.draw(at: origin) // 원본 이미지
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
