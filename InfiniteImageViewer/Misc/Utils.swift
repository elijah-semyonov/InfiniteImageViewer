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

func createOrthoMatrix(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> float4x4 {
    let rl = right - left
    let tb = top - bottom
    let fn = far - near

    return float4x4(
        [
            [2.0 / rl, 0.0, 0.0, 0.0],
            [0.0, 2.0 / tb, 0.0, 0.0],
            [0.0, 0.0, -2.0 / fn, 0.0],
            [-(right + left) / rl, -(top + bottom) / tb, -(far + near) / fn, 1.0]
        ]
    )
}
