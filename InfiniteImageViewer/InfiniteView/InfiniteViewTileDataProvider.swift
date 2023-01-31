//
//  InfiniteViewTileDataProvider.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import Foundation

protocol InfiniteViewTileDataProvider {
    func tileImageData(at index: InfiniteViewTileIndex) async throws -> Data
}
