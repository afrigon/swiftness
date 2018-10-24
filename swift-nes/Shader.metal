//
//  Shader.metal
//  cellular-automaton
//
//  Created by Alexandre Frigon on 2018-10-15.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 static_vertex(const device packed_float2* vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    return float4(vertex_array[vid], 0.0, 1.0);
}

fragment half4 static_fragment() {
    return half4(1.0);
}
