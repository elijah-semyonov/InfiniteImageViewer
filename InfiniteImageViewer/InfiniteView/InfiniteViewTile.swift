//
//  InfiniteViewTile.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import Foundation
import Metal
import MetalKit

class InfiniteViewTile {
    enum State {
        case loading
        case loaded(MTLTexture)
    }
    
    var state: State = .loading
    
    init(index: InfiniteViewTileIndex, provider: InfiniteViewTileDataProvider, loader: MTKTextureLoader) {
        state = .loading
        
        Task { @MainActor [weak self] in
            do {
                let data = try await provider.tileImageData(at: index)
                let texture = try await loader.newTexture(data: data)
                self?.state = .loaded(texture)
            } catch {
                debugPrint(error)
            }
        }
    }
}
