// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains routines used for color conversion
 */

#pragma once

#include <aliceVision/depthMap_mtl/Namespace.hpp>

/* Metal Headers */
#include <aliceVision/depthMap_mtl/metal/Math.hpp>

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

// for the R camera, image alpha should be at least 0.9f (computation area)
#define ALICEVISION_DEPTHMAP_RC_MIN_ALPHA (255.f * 0.9f)  // texture range (0, 255)

// for the T camera, image alpha should be at least 0.4f (masking)
#define ALICEVISION_DEPTHMAP_TC_MIN_ALPHA (255.f * 0.4f)  // texture range (0, 255)

/**
 * @brief XYZ (0..1) to CIELAB (0..255) assuming D65 whitepoint
 * @param[in] c the float3 XYZ
 * @return float3 CIELAB
 */
inline float3 xyz2lab(thread const float3& c)
{
    // assuming whitepoint D65, XYZ=(0.95047, 1.00000, 1.08883)
    float3 r = float3(c.x / 0.95047f, c.y, c.z / 1.08883f);

    float3 f = float3((r.x > 216.0f / 24389.0f ? av_cbrtf(r.x) : (24389.0f / 27.0f * r.x + 16.0f) / 116.0f),
                      (r.y > 216.0f / 24389.0f ? av_cbrtf(r.y) : (24389.0f / 27.0f * r.y + 16.0f) / 116.0f),
                      (r.z > 216.0f / 24389.0f ? av_cbrtf(r.z) : (24389.0f / 27.0f * r.z + 16.0f) / 116.0f));

    float3 out = float3(116.0f * f.y - 16.0f, 500.0f * (f.x - f.y), 200.0f * (f.y - f.z));

    // convert values to fit into 0..255 (could be out-of-range)
    // TODO FACA: use float textures, the values are out-of-range for a and b.
    out.x = out.x * 2.55f;
    out.y = out.y * 2.55f;
    out.z = out.z * 2.55f;
    return out;
}

/**
 * @brief Linear RGB (0..1) to XZY (0..1) using sRGB primaries
 * @param[in] c the float3 Linear RGB
 * @return float3 XYZ
 */
inline float3 rgb2xyz(thread const float3& c)
{
    return float3(0.4124564f * c.x + 0.3575761f * c.y + 0.1804375f * c.z,
                  0.2126729f * c.x + 0.7151522f * c.y + 0.0721750f * c.z,
                  0.0193339f * c.x + 0.1191920f * c.y + 0.9503041f * c.z);
}

/**
 * @brief Euclidean distance (float4, XYZ ignore W)
 * @param[in] x1 the first pixel color
 * @param[in] x2 the second pixel color
 * @return distance
 */
inline float euclideanDist3(thread const float4& x1, thread const float4& x2)
{
    // return sqrtf((x1.x - x2.x) * (x1.x - x2.x) + (x1.y - x2.y) * (x1.y - x2.y) + (x1.z - x2.z) * (x1.z - x2.z));
    return av_norm3d(x1.x - x2.x, x1.y - x2.y, x1.z - x2.z);
}

inline float CostYKfromLab(thread const float4& c1, thread const float4& c2, const float invGammaC)
{
    // euclidean distance in Lab, assuming linear RGB
    const float deltaC = euclideanDist3(c1, c2);

    return exp(-(deltaC * invGammaC));  // Yoon & Kweon
}

inline float CostYKfromLab(const int dx, const int dy, thread const float4& c1, thread const float4& c2, const float invGammaC, const float invGammaP)
{
    // const float deltaC = 0; // ignore colour difference

    //// AD in RGB
    // const float deltaC =
    //    fabsf(float(c1.x) - float(c2.x)) +
    //    fabsf(float(c1.y) - float(c2.y)) +
    //    fabsf(float(c1.z) - float(c2.z));

    //// euclidean distance in RGB
    // const float deltaC = euclideanDist3(
    //    uchar4_to_float3(c1),
    //    uchar4_to_float3(c2)
    //);

    //// euclidean distance in Lab, assuming sRGB
    // const float deltaC = euclideanDist3(
    //    xyz2lab(rgb2xyz(srgb2rgb(uchar4_to_float3(c1)))),
    //    xyz2lab(rgb2xyz(srgb2rgb(uchar4_to_float3(c2))))
    //);

    // euclidean distance in Lab, assuming linear RGB
    float deltaC = euclideanDist3(c1, c2);
    // const float deltaC = fmaxf(fabs(c1.x-c2.x),fmaxf(fabs(c1.y-c2.y),fabs(c1.z-c2.z)));

    deltaC *= invGammaC;

    // spatial distance to the center of the patch (in pixels)
    // without optimization
    // float deltaP = sqrtf(float(dx * dx + dy * dy));
    float deltaP = sqrt(float(dx * dx + dy * dy));

    deltaP *= invGammaP;

    deltaC += deltaP;

    return exp(-deltaC);  // Yoon & Kweon
    // return __expf(-(deltaC * deltaC / (2 * gammaC * gammaC))) * sqrtf(__expf(-(deltaP * deltaP / (2 * gammaP * gammaP)))); // DCB
    // return __expf(-((deltaC * deltaC / 2) * (invGammaC * invGammaC))) * sqrtf(__expf(-(((deltaP * deltaP / 2) * (invGammaP * invGammaP)))); // DCB
}

ALICEVISION_DEPTHMAP_MTL_NS_END
