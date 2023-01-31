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
            let matrix = positioning.orthogonalProjectionMatrix
            
            let v4 = matrix * Vec4f(input.x, input.y, 0.0, 1.0)
            
            let v2 = Vec2f(v4.x / v4.w, v4.y / v4.w)

            return v2
        }
        
        self.init(topLeft: transform(topLeft), bottomRight: transform(bottomRight))
    }
}
