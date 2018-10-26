//
//    MIT License
//
//    Copyright (c) 2018 Alexandre Frigon
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
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
