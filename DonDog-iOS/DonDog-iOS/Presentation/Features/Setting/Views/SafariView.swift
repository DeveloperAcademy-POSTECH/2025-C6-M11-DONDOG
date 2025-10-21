//
//  SafariView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/21/25.
//

import SwiftUI
import WebKit

struct InAppWebSheet: View {
    let url: URL
    @State private var isLoading = true

    var body: some View {
        ZStack {
            WebView(url: url, isLoading: $isLoading)
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // no-op
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let parent: WebView
        init(_ parent: WebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}
