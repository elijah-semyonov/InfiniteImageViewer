//
//  Utils.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import Metal

func loadRenderPipelineState(name: String, device: MTLDevice, library: MTLLibrary) -> MTLRenderPipelineState? {
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
    
    guard let vertexFunction = library.makeFunction(name: "\(name)_vf") else {
        return nil
    }
    
    guard let fragmentFunction = library.makeFunction(name: "\(name)_ff") else {
        return nil
    }
    
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    
    return try? device.makeRenderPipelineState(descriptor: descriptor)
}
