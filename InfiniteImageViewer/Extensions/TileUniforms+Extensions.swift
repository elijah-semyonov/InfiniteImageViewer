//
//  TileUniforms+Extensions.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import Foundation

extension TileUniforms {
    init(index: InfiniteViewTileIndex, positioning: InfiniteViewPositioning) {
        let topLeft = Vec2f(x: Float(index.x) * tileSize, y: Float(index.y) * tileSize)
        let bottomRight = topLeft + Vec2f(repeating: tileSize)
        
        /// Transform from UIKit-based points to NDC
        let transform = { (input: Vec2f) -> Vec2f in
            var v = input - positioning.center
            v /= positioning.span
            
            v = (v * 2.0) - Vec2f(repeating: 1.0)
            
            v.y = -v.y
            
            return v
        }
        
        self.init(topLeft: transform(topLeft), bottomRight: transform(bottomRight))
    }
}
