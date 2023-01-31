//
//  TileDataProvider.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import Foundation

class MockTileDataProvider: InfiniteViewTileDataProvider {
    func tileImageData(at index: InfiniteViewTileIndex) async throws -> Data {
        try await downloadRandomImageData()
    }
    
    private func downloadRandomImageData() async throws -> Data {
        let request = URLRequest(url: URL(string: "https://picsum.photos/200/200")!)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        return data
    }
}
