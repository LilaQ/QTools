//
//  File.swift
//  
//
//  Created by Jan on 22.11.22.
//

import SwiftUI

@available(iOS 15.0, *)
@available(macOS 12.0, *)
public final class CachedAsyncImage<Content>: SwiftUI.View where Content: SwiftUI.View {

    private let url: URL
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    
    public init(
        url: URL,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }
    
    public var body: some View {
        if let image = ImageCache[url] {
            self.content(.success(image))
        } else {
            AsyncImage(url: url, scale: scale, transaction: transaction) { phase in
                self.cacheAndRender(phase: phase)
            }
        }
    }
    
    private func cacheAndRender(phase: AsyncImagePhase) -> some View {
        if case .success(let image) = phase {
            ImageCache[url] = image
        }
        return content(phase)
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
fileprivate class ImageCache {
    static private var cache: [URL: Image] = [:]
    static subscript(url: URL) -> Image? {
        get {
            cache[url]
        }
        set {
            cache[url] = newValue
        }
    }
}
