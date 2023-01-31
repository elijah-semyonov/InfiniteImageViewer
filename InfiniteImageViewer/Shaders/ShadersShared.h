//
//  ShadersShared.h
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

#ifndef ShadersShared_h
#define ShadersShared_h

#ifdef __METAL_VERSION__

#include <metal_stdlib>

typedef metal::float2 Vec2f;

struct QuadVertex {
    Vec2f position;
    Vec2f texCoord;
};

constant QuadVertex quadVertices[] = {
    {
        .position = Vec2f(-1.0, -1.0),
        .texCoord = Vec2f(0.0, 1.0)
    },
    {
        .position = Vec2f(-1.0, 1.0),
        .texCoord = Vec2f(0.0, 0.0)
    },
    {
        .position = Vec2f(1.0, 1.0),
        .texCoord = Vec2f(1.0, 0.0)
    },
    {
        .position = Vec2f(1.0, -1.0),
        .texCoord = Vec2f(1.0, 1.0)
    }
};

constant uint quadIndices[] = {
    0, 1, 2,
    0, 2, 3
};

inline QuadVertex quadVertexAtIndex(uint index) {
    index = metal::clamp(index, uint{0}, uint{5});
    
    return quadVertices[quadIndices[index]];
}

#else

#include <simd/simd.h>

typedef vector_float2 Vec2f;
typedef vector_float4 Vec4f;
typedef matrix_float4x4 Mat4x4f;

#endif

struct BackgroundUniforms {
    Vec2f viewportMin;
    Vec2f viewportMax;
    float tileSize;
};

struct TileUniforms {
    Vec2f topLeft;
    Vec2f bottomRight;
};

#endif /* ShadersShared_h */
