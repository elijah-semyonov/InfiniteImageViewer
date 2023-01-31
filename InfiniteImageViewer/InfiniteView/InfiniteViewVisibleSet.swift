//
//  InfiniteViewVisibleSet.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import Foundation
import MetalKit

class InfiniteViewVisibleSet {
    private(set) var indexBounds: InfiniteViewIndexBounds? {
        didSet {
            if indexBounds != oldValue {
                updateTilesAfterBoundsChange(from: oldValue, to: indexBounds!)
            }
        }
    }
    private(set) var tiles: [InfiniteViewTileIndex: InfiniteViewTile] = [:]
    private var positioning: InfiniteViewPositioning?
    private let provider: InfiniteViewTileDataProvider
    private let loader: MTKTextureLoader
    private let tileRenderPipelineState: MTLRenderPipelineState
    
    init?(provider: InfiniteViewTileDataProvider, device: MTLDevice, library: MTLLibrary) {
        self.provider = provider
        self.loader = .init(device: device)
        
        guard let tileRenderPipelineState = loadRenderPipelineState(name: "tile", device: device, library: library) else {
            return nil
        }
        
        self.tileRenderPipelineState = tileRenderPipelineState
    }
    
    func update(using positioning: InfiniteViewPositioning) {
        self.positioning = positioning
        indexBounds = .init(positioning: positioning)
    }
    
    func encode(to encoder: MTLRenderCommandEncoder) {
        guard let positioning else {
            return
        }
        
        encoder.setRenderPipelineState(tileRenderPipelineState)
        
        for (index, tile) in tiles {
            switch tile.state {
            case .loading:
                continue
            case .loaded(let texture):
                encoder.setVertexValue(TileUniforms(index: index, positioning: positioning), index: 0)
                encoder.setFragmentTexture(texture, index: 0)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            }
        }
    }
    
    private func updateTilesAfterBoundsChange(from: InfiniteViewIndexBounds?, to: InfiniteViewIndexBounds) {        
        if from == nil {
            to.forEachTileIndexInside { index in
                tiles[index] = .init(index: index, provider: provider, loader: loader)
            }
        } else {
            tiles = tiles.filter { (index, _) in
                to.contains(index)
            }
            
            to.forEachTileIndexInside { index in
                if tiles[index] == nil {
                    tiles[index] = .init(index: index, provider: provider, loader: loader)
                }
            }
        }
    }
}
