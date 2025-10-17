//
//  SwipeBackUtils.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/16/25.
//

import Foundation
import UIKit
import SwiftUI

extension View {
    func backHiddenSwipeEnabled() -> some View {
        self.modifier(BackHiddenSwipeEnabled())
    }
}

struct BackHiddenSwipeEnabled: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .background(EnableSwipeBackGesture())
    }
}

struct EnableSwipeBackGesture: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            controller.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            controller.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
