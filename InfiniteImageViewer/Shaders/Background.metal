//
//  Background.metal
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

#include "ShadersShared.h"

using namespace metal;


struct BackgroundVaryings {
    float4 position [[position]];
    float2 texCoord;
};

vertex BackgroundVaryings background_vf
(
 uint vId [[vertex_id]]
) {
    auto quadVertex = quadVertexAtIndex(vId);
    
    return {
        .position = float4(quadVertex.position, 0.0, 1.0),
        .texCoord = quadVertex.texCoord
    };
}

fragment half4 background_ff
(
 BackgroundVaryings varyings [[stage_in]],
 constant BackgroundUniforms& uniforms [[buffer(0)]]
) {
    auto coordinate = mix(uniforms.viewportMin, uniforms.viewportMax, varyings.texCoord);
    
    auto tile = coordinate / float2(100.0);
    auto tileFract = fract(tile);
    
    auto xySigns = step(0.5, tileFract) * 2.0 - 1.0;
    auto t = xySigns.x * xySigns.y * 0.5 + 0.5;
    
    return mix(0.2h, 0.5h, half(t));
}
