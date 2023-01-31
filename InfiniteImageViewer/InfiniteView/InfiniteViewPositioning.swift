//
//  InfiniteViewPositioning.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import Foundation

struct InfiniteViewPositioning {
    var center: Vec2f
    var span: Vec2f
    
    var orthogonalProjectionMatrix: Mat4x4f {
        let halfSpan = span / 2.0
        
        let topLeft = center - halfSpan
        let bottomRight = center + halfSpan
        
        let left = topLeft.x
        let right = bottomRight.x
        let top = topLeft.y
        let bottom = bottomRight.y
        let near: Float = -1.0
        let far: Float = 1.0
        let rl = right - left
        let tb = top - bottom
        let fn = far - near

        return Mat4x4f(columns: (
            Vec4f(2.0 / rl, 0.0, 0.0, 0.0),
            Vec4f(0.0, 2.0 / tb, 0.0, 0.0),
            Vec4f(0.0, 0.0, -2.0 / fn, 0.0),
            Vec4f(-(right + left) / rl, -(top + bottom) / tb, -(far + near) / fn, 1.0)
        ))
    }
}
