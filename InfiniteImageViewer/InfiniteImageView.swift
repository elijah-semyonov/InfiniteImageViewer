//
//  InfiniteImageView.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import UIKit

struct InfiniteImageTileIndex {
    let x: Int
    let y: Int
}

protocol InfiniteImageViewTileDataProvider {
    func tileImageData(at index: InfiniteImageTileIndex) async throws -> Data
}

class InfiniteImageView: UIView {
    class override var layerClass: AnyClass {
        CAMetalLayer.self
    }
    
    var contentOffset: CGPoint = .zero
    
    private let tileDataProvider: InfiniteImageViewTileDataProvider
    
    init(tileDataProvider: InfiniteImageViewTileDataProvider) {
        self.tileDataProvider = tileDataProvider
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
}
