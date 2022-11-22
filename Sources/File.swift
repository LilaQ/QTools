//
//  File.swift
//  
//
//  Created by Jan on 22.11.22.
//

import SwiftUI
import CachedAsyncImage

struct Test: View {
    var body: some View {
        CachedAsyncImage(url: URL(string: "https://picsum.photos/536/354"), content: { image in
            image
                .resizable()
                .frame(width: 200, height: 100)
        }, placeholder: {
            Text("asd")
        })
    }
}
