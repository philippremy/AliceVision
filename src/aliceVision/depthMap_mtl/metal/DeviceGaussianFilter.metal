// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/Types.hpp>
#include <aliceVision/depthMap_mtl/Namespace.hpp>

#include <aliceVision/depthMap_mtl/private/KernelArgs.hpp>

/* Metal Headers */
#include <aliceVision/depthMap_mtl/metal/DeviceTextureSamplers.hpp>
#include <aliceVision/depthMap_mtl/metal/DeviceGaussianArrays.hpp>

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

[[kernel]] void
kernel_downscaleWithGaussianBlur(texture2d<MTLRGBABaseType, access::write> out_downscaledTex [[texture(0)]],
                                 texture2d<MTLRGBABaseType, access::sample> in_imgTex [[texture(1)]],  // Not normalized
                                 device const ArgsDownscaleWithGaussianBlur& kernelArgs [[buffer(30)]],
                                 const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int x = gid.x;
    const unsigned int y = gid.y;
    
    const unsigned int downscaledImgWidth = out_downscaledTex.get_width();
    const unsigned int downscaledImgHeight = out_downscaledTex.get_height();

    if ((x < downscaledImgWidth) && (y < downscaledImgHeight))
    {
        const float s = float(kernelArgs.downscale) * 0.5f;

        float4 accPix = float4(0.0f, 0.0f, 0.0f, 0.0f);
        float sumFactor = 0.0f;

        for (int i = -kernelArgs.gaussRadius; i <= kernelArgs.gaussRadius; i++)
        {
            for (int j = -kernelArgs.gaussRadius; j <= kernelArgs.gaussRadius; j++)
            {
                const float4 curPix = float4(in_imgTex.sample(TEX_SAMPLER_NONORM, float(x * kernelArgs.downscale + j) + s, float(y * kernelArgs.downscale + i) + s));
                const float factor = getGauss(kernelArgs.downscale - 1, i + kernelArgs.gaussRadius) * getGauss(kernelArgs.downscale - 1, j + kernelArgs.gaussRadius);  // domain factor

                accPix = accPix + curPix * factor;
                sumFactor += factor;
            }
        }

        MTLRGBA out;
        out.x = accPix.x / sumFactor;
        out.y = accPix.y / sumFactor;
        out.z = accPix.z / sumFactor;
        out.w = accPix.w / sumFactor;
        
        out_downscaledTex.write(out, uint2(x, y));
    }
}

ALICEVISION_DEPTHMAP_MTL_NS_END
