//
//  TileDataProvider.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import Foundation

class TileDataProvider: InfiniteImageViewTileDataProvider {
    func tileImageData(at index: InfiniteImageTileIndex) async throws -> Data {
        fatalError()
    }
    
    private func downloadRandomImageData() async throws -> Data {
        fatalError()
    }
}
