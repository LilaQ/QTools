//
//  File.swift
//  
//
//  Created by Jan on 22.11.22.
//

import SwiftUI

@available(iOS 15.0, *)
@available(macOS 12.0, *)
public struct CachedAsyncImage<Content: View, Placeholder: View>: SwiftUI.View {

    private let url: URL!
    private let scale: CGFloat
    private let transaction: Transaction
    private var content: ((AsyncImagePhase) -> Content)? = nil
    private var contentImage: ((Image) -> Content)? = nil
    private var placeholder: (() -> Placeholder)? = nil
    
    public init(
        url: URL,
        scale: CGFloat = 1.0,
        rescaleToWidth: CGFloat? = nil,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) where Placeholder == EmptyView {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }
    
    public var body: some View {
        
        //  first intializer used
        if let c = content {
            if let image = PersistentImageCache[url] {
                c(.success(image))
            } else {
                AsyncImage(url: url, scale: scale, transaction: transaction) { phase in
                    self.cacheAndRender(phase: phase)
                }
            }
        }
        
        //  initializer with placeholder
        else if let c = contentImage, let p = placeholder {
            if let image = PersistentImageCache[url] {
                cacheAndRender(img: image)
            } else {
                AsyncImage(url: url, scale: scale, content: c, placeholder: p)
            }
        }
    }
    
    private func cacheAndRender(phase: AsyncImagePhase) -> some View {
        if case .success(let image) = phase {
            PersistentImageCache[url] = image
        }
        return content!(phase)
    }
    
    private func cacheAndRender(img: Image) -> some View {
        PersistentImageCache[url] = img
        return contentImage!(img)
    }
}

//@available(iOS 13.0, *)
//@available(macOS 10.15, *)
//fileprivate class ImageCache {
//    static private var cache: [URL: Image] = [:]
//    static subscript(url: URL) -> Image? {
//        get {
//            cache[url]
//        }
//        set {
//            cache[url] = newValue
//        }
//    }
//}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
fileprivate class PersistentImageCache {
    static private var cache: NSCache<NSString, NSData> = NSCache<NSString, NSData>()
    static subscript(url: URL, resizeWidth: CGFloat? = nil) -> Image? {
        get {
            guard let data = cache.object(forKey: url.absoluteString as NSString),
                  let image = NSImage(data: data as Data)
            else { return nil }
            return Image(nsImage: image)
        }
        set {
            guard var img = NSImage(contentsOf: url) else { return }
            var data: NSData? = nil
            if let w = resizeWidth {
                let h = Int((img.size.width / w) * img.size.height)
                let w = Int(w)
                img = resize(image: img, w: w, h: h)
                guard let d = img.tiffRepresentation else { return }
                data = NSData(data: d)
                print("Storing resized to w: \(w), h: \(h)")
            }
            guard let data = data else { return }
            cache.setObject(data, forKey: url.absoluteString as NSString)
        }
    }
    
    private static func resize(image: NSImage, w: Int, h: Int) -> NSImage {
        var destSize = NSMakeSize(CGFloat(w), CGFloat(h))
        var newImage = NSImage(size: destSize)
        newImage.lockFocus()
        image.draw(in: NSMakeRect(0, 0, destSize.width, destSize.height), from: NSMakeRect(0, 0, image.size.width, image.size.height), operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.tiffRepresentation!)!
    }
}

@available(iOS 15.0, *)
@available(macOS 12.0, *)
extension CachedAsyncImage {
    public init(
        url: URL?,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) where Placeholder == EmptyView {
        self.url = url
        self.scale = 1.0
        self.transaction = Transaction()
        self.content = content
    }
    
    public init(
        url: URL?,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = 1.0
        self.transaction = Transaction()
        self.contentImage = content
        self.placeholder = placeholder
    }
}
