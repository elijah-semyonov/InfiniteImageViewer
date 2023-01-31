//
//  InfiniteViewportIndexBounds.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import Foundation

struct InfiniteViewIndexBounds: Hashable {
    let min: InfiniteViewTileIndex
    let max: InfiniteViewTileIndex
    
    init(positioning: InfiniteViewPositioning) {
        let (center, span) = (positioning.center, positioning.span)
        let halfSpan = span / 2.0
        
        let left = Int((center.x - halfSpan.x) / tileSize) - 1
        let right = Int((center.x + halfSpan.x) / tileSize) + 1
        let top = Int((center.y - halfSpan.y) / tileSize) - 1
        let bottom = Int((center.y + halfSpan.y) / tileSize) + 1
        
        min = .init(x: left, y: top)
        max = .init(x: right, y: bottom)
    }
    
    func contains(_ index: InfiniteViewTileIndex) -> Bool {
        index.x >= min.x && index.x <= max.x && index.y >= min.y && index.y <= max.y
    }
    
    func forEachTileIndexInside(_ closure: (InfiniteViewTileIndex) -> Void) {
        for x in min.x...max.x {
            for y in min.y...max.y {
                closure(.init(x: x, y: y))
            }
        }
    }
}
