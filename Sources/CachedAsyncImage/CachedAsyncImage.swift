//
//  File.swift
//  
//
//  Created by Jan on 22.11.22.
//

import SwiftUI

@available(iOS 15.0, *)
@available(macOS 12.0, *)
public struct CachedAsyncImage<Content>: SwiftUI.View where Content: SwiftUI.View {

    private let url: URL!
    private let scale: CGFloat
    private let transaction: Transaction
    private var content: ((AsyncImagePhase) -> Content)? = nil
    private var contentImage: ((Image) -> Content)? = nil
    private var placeholder: (() -> Content)? = nil
    
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
    
    public init(
        url: URL?,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.scale = 1.0
        self.transaction = Transaction()
        self.content = content
    }
    
    public init(
        url: URL?,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Content
    ) {
        self.url = url
        self.scale = 1.0
        self.transaction = Transaction()
        self.contentImage = content
        self.placeholder = placeholder
    }
    
    @ViewBuilder public var body: some View {
        
        //  first intializer used
        if let c = content {
            if let image = ImageCache[url] {
                c(.success(image))
            } else {
                AsyncImage(url: url, scale: scale, transaction: transaction) { phase in
                    self.cacheAndRender(phase: phase)
                }
            }
        }
        
        //  initializer with placeholder
        else if let c = contentImage, let p = placeholder {
            if let image = ImageCache[url] {
                c(image)
            } else {
                AsyncImage(url: url, scale: scale, content: { i in
                    cacheAndRender(img: i)
                }, placeholder: p)
            }
        }
    }
    
    private func cacheAndRender(phase: AsyncImagePhase) -> some View {
        if case .success(let image) = phase {
            ImageCache[url] = image
        }
        return content!(phase)
    }
    
    private func cacheAndRender(img: Image) -> some View {
        ImageCache[url] = img
        return contentImage!(img)
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
