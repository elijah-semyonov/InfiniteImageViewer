//
//  Metal+Extensions.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import Metal

extension MTLRenderCommandEncoder {
    func setVertexValue<T>(_ value: T, index: Int) {
        var value = value
        setVertexBytes(&value, length: MemoryLayout<T>.stride, index: index)
    }
    
    func setFragmentValue<T>(_ value: T, index: Int) {
        var value = value
        setFragmentBytes(&value, length: MemoryLayout<T>.stride, index: index)
    }
}
