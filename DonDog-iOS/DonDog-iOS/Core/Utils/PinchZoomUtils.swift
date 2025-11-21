//
//  PinchZoomUtils.swift
//  DonDog-iOS
//
//  Created by Ito on 11/20/25.
//

import SwiftUI
import UIKit

// MARK: - PinchZoom Extension
extension View {
    @ViewBuilder
    func pinchZoom(_ dimsBackground: Bool = true, isZooming: Binding<Bool>? = nil) -> some View {
        PinchZoomHelper(dimsBackground: dimsBackground, isZooming: isZooming ?? .constant(false)) {
            self
        }
    }
}

// MARK: - Zoom Container
struct ZoomContainer<Content: View>: View {
    var content: Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    private var containerData = ZoomContainerData()
    
    var body: some View {
        GeometryReader { _ in
            content
                .environment(containerData)
            
            ZStack(alignment: .topLeading) {
                if let view = containerData.zoomingView {
                    Group {
                        if containerData.dimsBackground {
                            Rectangle()
                                .fill(.ppRealBlack)
                        }
                        
                        view
                            .scaleEffect(containerData.zoom, anchor: containerData.zoomAnchor)
                            .offset(containerData.dragOffset)
                            .offset(x: containerData.viewRect.minX, y: containerData.viewRect.minY)
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Zoom Container Data
@Observable
class ZoomContainerData {
    var zoomingView: AnyView?
    var viewRect: CGRect = .zero
    var dimsBackground: Bool = false
    var zoom: CGFloat = 1
    var zoomAnchor: UnitPoint = .center
    var dragOffset: CGSize = .zero
    var isResetting: Bool = false
    var isZooming: Bool = false
}

// MARK: - PinchZoom Helper
struct PinchZoomHelper<Content: View>: View {
    var dimsBackground: Bool
    @ViewBuilder var content: Content
    @Environment(ZoomContainerData.self) private var containerData
    @State private var config: Config = .init()
    @Binding var isZooming: Bool
    
    // 명시적 초기화자 추가
    init(dimsBackground: Bool, isZooming: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.dimsBackground = dimsBackground
        self._isZooming = isZooming
        self.content = content()
    }
    
    var body: some View {
        content
            .opacity(config.hidesSourceView ? 0 : 1)
            .overlay(GestureOverlay(config: $config))
            .overlay {
                GeometryReader {
                    let rect = $0.frame(in: .global)
                    
                    Color.clear
                        .onChange(of: config.isGestureActive) { oldValue, newValue in
                            guard !containerData.isResetting else { return }
                            if newValue {
                                containerData.viewRect = rect
                                containerData.zoomAnchor = config.zoomAnchor
                                containerData.dimsBackground = dimsBackground
                                containerData.zoomingView = .init(erasing: content)
                                config.hidesSourceView = true
                                containerData.isZooming = true
                                isZooming = true
                            } else {
                                containerData.isResetting = true
                                withAnimation(.snappy(duration: 0.3, extraBounce: 0), completionCriteria: .logicallyComplete) {
                                    containerData.dragOffset = .zero
                                    containerData.zoom = 1
                                } completion: {
                                    config = .init()
                                    containerData.zoomingView = nil
                                    containerData.isResetting = false
                                    containerData.isZooming = false
                                    isZooming = false
                                }
                            }
                        }
                        .onChange(of: config) { oldValue, newValue in
                            if config.isGestureActive && !containerData.isResetting {
                                containerData.zoom = config.zoom
                                containerData.dragOffset = config.dragOffset
                            }
                        }
                }
            }
    }
}

// MARK: - Gesture Overlay
struct GestureOverlay: UIViewRepresentable {
    @Binding var config: Config
    
    func makeCoordinator() -> Coordinator {
        Coordinator(config: $config)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        // Pan Gesture (두 손가락 드래그)
        let panGesture = UIPanGestureRecognizer()
        panGesture.name = "PINCHPANGESTURE"
        panGesture.minimumNumberOfTouches = 2
        panGesture.addTarget(context.coordinator, action: #selector(Coordinator.panGesture(gesture:)))
        panGesture.delegate = context.coordinator
        view.addGestureRecognizer(panGesture)
        
        // Pinch Gesture (핀치 줌)
        let pinchGesture = UIPinchGestureRecognizer()
        pinchGesture.name = "PINCHZOOMGESTURE"
        pinchGesture.addTarget(context.coordinator, action: #selector(Coordinator.pinchGesture(gesture:)))
        pinchGesture.delegate = context.coordinator
        view.addGestureRecognizer(pinchGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @Binding var config: Config
        
        init(config: Binding<Config>) {
            self._config = config
        }
        
        @objc
        func panGesture(gesture: UIPanGestureRecognizer) {
            if gesture.state == .began || gesture.state == .changed {
                let translation = gesture.translation(in: gesture.view)
                config.dragOffset = .init(width: translation.x, height: translation.y)
                config.isGestureActive = true
            } else {
                config.isGestureActive = false
            }
        }
        
        @objc
        func pinchGesture(gesture: UIPinchGestureRecognizer) {
            if gesture.state == .began {
                let location = gesture.location(in: gesture.view)
                if let bounds = gesture.view?.bounds {
                    config.zoomAnchor = .init(x: location.x / bounds.width, y: location.y / bounds.height)
                }
            }
            
            if gesture.state == .began || gesture.state == .changed {
                let scale = max(gesture.scale, 1)
                config.zoom = scale
                config.isGestureActive = true
            } else {
                config.isGestureActive = false
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer.name == "PINCHPANGESTURE" && otherGestureRecognizer.name == "PINCHZOOMGESTURE" {
                return true
            }
            return false
        }
    }
}

// MARK: - Config
struct Config: Equatable {
    var isGestureActive: Bool = false
    var zoom: CGFloat = 1
    var zoomAnchor: UnitPoint = .center
    var dragOffset: CGSize = .zero
    var hidesSourceView: Bool = false
}
