//
//  Created by Alexandre Frigon on 2018-10-15.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 textureCoordinates [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinates [[user(tex_coords)]];
};

vertex VertexOut textured_vertex(uint vertexID [[vertex_id]], const device VertexIn* vertexArray [[buffer(0)]]) {
    VertexOut outVertex;
    outVertex.position = float4(vertexArray[vertexID].position, 0.0, 1.0);
    outVertex.textureCoordinates = vertexArray[vertexID].textureCoordinates;
    return outVertex;
}

fragment half4 textured_fragment(VertexOut in [[stage_in]], texture2d<half> diffuseMap [[texture(0)]], sampler textureSampler [[sampler(0)]]) {
    return diffuseMap.sample(textureSampler, in.textureCoordinates);
}
