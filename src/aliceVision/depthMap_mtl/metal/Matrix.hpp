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

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

inline float3 av_cross(thread const float3& a, thread const float3& b)
{ return float3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x); }

inline float av_dist(thread const float3& a, thread const float3& b)
{
    return av_size(a - b);
}

inline float3 M3x3mulV2(constant const float* M3x3, thread const float2& V)
{ return float3(M3x3[0] * V.x + M3x3[3] * V.y + M3x3[6], M3x3[1] * V.x + M3x3[4] * V.y + M3x3[7], M3x3[2] * V.x + M3x3[5] * V.y + M3x3[8]); }

inline float3 M3x4mulV3(constant const float* M3x4, thread const float3& V)
{
    return float3(M3x4[0] * V.x + M3x4[3] * V.y + M3x4[6] * V.z + M3x4[9],
                  M3x4[1] * V.x + M3x4[4] * V.y + M3x4[7] * V.z + M3x4[10],
                  M3x4[2] * V.x + M3x4[5] * V.y + M3x4[8] * V.z + M3x4[11]);
}

inline float3 linePlaneIntersect(constant const float3& linePoint,
                                 thread const float3& lineVect,
                                 thread const float3& planePoint,
                                 constant const float3& planeNormal)
{
    const float k = (dot(planePoint, planeNormal) - dot(planeNormal, linePoint)) / dot(planeNormal, lineVect);
    return linePoint + lineVect * k;
}

inline float2 project3DPoint(constant const float* M3x4, thread const float3& V)
{
    // without optimization
    // const float3 p = M3x4mulV3(M3x4, V);
    // return make_float2(p.x / p.z, p.y / p.z);

    float3 p = M3x4mulV3(M3x4, V);
    const float pzInv = divide(1.0f, p.z);
    return float2(p.x * pzInv, p.y * pzInv);
}

inline float pointLineDistance3D(thread const float3& point, constant const float3& linePoint, thread const float3& lineVectNormalized)
{ return av_size(av_cross(lineVectNormalized, linePoint - point)); }

inline float3 closestPointToLine3D(thread const float3& point, thread const float3& linePoint, thread const float3& lineVectNormalized)
{
    return linePoint + lineVectNormalized * dot(lineVectNormalized, point - linePoint);
}

inline float angleBetwABandAC(thread const float3& A, thread const float3& B, thread const float3& C)
{
    float3 V1 = B - A;
    float3 V2 = C - A;

    av_normalize(V1);
    av_normalize(V2);

    const float x = float(V1.x * V2.x + V1.y * V2.y + V1.z * V2.z);
    float a = acos(x);
    a = isinf(a) ? 0.0 : a;
    return float(abs(a) / (M_PI_F / 180.0));
}

ALICEVISION_DEPTHMAP_MTL_NS_END
