// This file is part of the AliceVision project.
// Copyright (c) 2022 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include <aliceVision/depthMap_mtl/Namespace.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

ALICEVISION_DEPTHMAP_MTL_NS_START

/**
 * @struct DeviceCameraParams
 *
 * @brief Support class to maintain useful camera parameters in device
 *        memory
 */
struct DeviceCameraParams
{
    float P[12];
    float iP[9];
    float R[9];
    float iR[9];
    float K[9];
    float iK[9];
    float3 C;
    float3 XVect;
    float3 YVect;
    float3 ZVect;
};

ALICEVISION_DEPTHMAP_MTL_NS_END
