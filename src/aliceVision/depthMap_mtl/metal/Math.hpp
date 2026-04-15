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

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

inline float av_cbrtf(float x)
{
    if (isnan(x) || isinf(x) || x == 0.0f)
        return x;

    return copysign(pow(abs(x), 1.0f / 3.0f), x);
}

inline void av_normalize(thread float3& a)
{
    float d = sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
    a.x /= d;
    a.y /= d;
    a.z /= d;
}

inline float av_size(thread const float3& a) { return sqrt(a.x * a.x + a.y * a.y + a.z * a.z); }

inline float av_size(thread const float2& a) { return sqrt(a.x * a.x + a.y * a.y); }

inline float av_norm3d(float a, float b, float c) {
    return length(float3(a, b , c));
}

/**
 * @brief Sigmoid function filtering
 * @note f(x) = min + (max-min) * \frac{1}{1 + e^{10 * (x - mid) / width}}
 * @see https://www.desmos.com/calculator/1qvampwbyx
 */
inline float av_sigmoid(float zeroVal, float endVal, float sigwidth, float sigMid, float xval)
{
    return zeroVal + (endVal - zeroVal) * (1.0f / (1.0f + exp(10.0f * ((xval - sigMid) / sigwidth))));
}

/**
 * @brief Sigmoid function filtering
 * @note f(x) = min + (max-min) * \frac{1}{1 + e^{10 * (mid - x) / width}}
 */
inline float sigmoid2(float zeroVal, float endVal, float sigwidth, float sigMid, float xval)
{
    return zeroVal + (endVal - zeroVal) * (1.0f / (1.0f + exp(10.0f * ((sigMid - xval) / sigwidth))));
}

inline float av_multi_min(float a, float b, float c, float d)
{
  return min(min(min(a, b), c), d);
}

ALICEVISION_DEPTHMAP_MTL_NS_END
