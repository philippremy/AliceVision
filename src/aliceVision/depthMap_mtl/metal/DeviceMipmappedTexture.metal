// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/Types.hpp>
#include <aliceVision/depthMap_mtl/Namespace.hpp>

/* Metal Headers */
#include <aliceVision/depthMap_mtl/metal/DeviceTextureSamplers.hpp>
#include <aliceVision/depthMap_mtl/metal/DeviceGaussianArrays.hpp>

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

/* TRadius is usually templated, currently with the value 2 */
constant constexpr const int TRadius = 2;

[[kernel]] void
kernel_createMipmappedArrayLevel(texture2d<MTLRGBABaseType, access::sample> tex_prevLevel [[texture(0)]], // Normalized
                                 texture2d<MTLRGBABaseType, access::write> tex_currLevel [[texture(1)]],
                                 const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int x = gid.x;
    const unsigned int y = gid.y;
    
    const unsigned int width = tex_currLevel.get_width();
    const unsigned int height = tex_currLevel.get_height();
    
    if (x >= width || y >= height)
        return;
    
    const float px = 1.f / float(width);
    const float py = 1.f / float(height);
    
    float4 sumColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
    float sumFactor = 0.0f;
    
    #pragma unroll
    for(int i = -TRadius; i <= TRadius; i++)
    {
        
        #pragma unroll
        for(int j = -TRadius; j <= TRadius; j++)
        {
            // domain factor
            const float factor = getGauss(1, i + TRadius) * getGauss(1, j + TRadius);

            // normalized coordinates
            const float u = (x + j + 0.5f) * px;
            const float v = (y + i + 0.5f) * py;

            // current pixel color
            const float4 color = float4(tex_prevLevel.sample(TEX_SAMPLER_NORM, float2(u, v)));

            // sum color
            sumColor = sumColor + color * factor;

            // sum factor
            sumFactor += factor;
        }
    }
    
    const float4 color = sumColor / sumFactor;
    
    MTLRGBA out;
    out.x = MTLRGBABaseType(color.x);
    out.y = MTLRGBABaseType(color.y);
    out.z = MTLRGBABaseType(color.z);
    out.w = MTLRGBABaseType(color.w);

    // write output color
    tex_currLevel.write(out, uint2(x, y));
}

ALICEVISION_DEPTHMAP_MTL_NS_END
