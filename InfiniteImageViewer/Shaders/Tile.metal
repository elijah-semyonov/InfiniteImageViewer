//
//  Tile.metal
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

#include "ShadersShared.h"

using namespace metal;


struct TileVaryings {
    float4 position [[position]];
    float2 texCoord;
};

vertex TileVaryings tile_vf
(
 uint vId [[vertex_id]],
 constant TileUniforms& uniforms [[buffer(0)]]
) {
    auto quadVertex = quadVertexAtIndex(vId);
    
    auto position = mix(uniforms.topLeft, uniforms.bottomRight, quadVertex.texCoord);
    
    return {
        .position = float4(position, 0.0, 1.0),
        .texCoord = quadVertex.texCoord
    };
}

constexpr sampler defaultSampler(min_filter::nearest, mag_filter::linear, mip_filter::linear);

fragment half4 tile_ff
(
 TileVaryings varyings [[stage_in]],
 texture2d<half, access::sample> texture [[texture(0)]]
) {
    return texture.sample(defaultSampler, varyings.texCoord);
}
