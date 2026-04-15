// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/Types.hpp>
#include <aliceVision/depthMap_mtl/Namespace.hpp>

/* Metal Headers */
#include <aliceVision/depthMap_mtl/metal/Color.hpp>
#include <aliceVision/depthMap_mtl/metal/DeviceTextureSamplers.hpp>

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

[[kernel]] void
kernel_rgb2lab(texture2d<MTLRGBABaseType, access::read_write> out_downscaledTex [[texture(0)]],
               const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int x = gid.x;
    const unsigned int y = gid.y;

    const unsigned int texWidth = out_downscaledTex.get_width();
    const unsigned int texHeight = out_downscaledTex.get_height();
    
    if((x >= texWidth) || (y >= texHeight))
        return;
    
    thread const MTLRGBA& rgba = out_downscaledTex.read(uint2(x, y));
    
    // MTLRGBA (uchar4 or float4 or half4) in range (0, 255)
    // rgb2xyz needs RGB in range (0, 1)
    constexpr float d = 1 / 255.f;
    
    float3 flab = xyz2lab(rgb2xyz(float3(float(rgba.x) * d, float(rgba.y) * d, float(rgba.z) * d)));
    
    MTLRGBA out;
    out.x = flab.x;
    out.y = flab.y;
    out.z = flab.z;
    out.w = rgba.w;
    
    out_downscaledTex.write(out, uint2(x, y));
}

ALICEVISION_DEPTHMAP_MTL_NS_END
