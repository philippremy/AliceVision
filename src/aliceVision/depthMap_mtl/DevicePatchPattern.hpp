// This file is part of the AliceVision project.
// Copyright (c) 2023 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include <aliceVision/depthMap_mtl/Config.h>
#include <aliceVision/depthMap_mtl/Namespace.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

ALICEVISION_DEPTHMAP_MTL_NS_START

/**
 * @struct DevicePatchPatternSubpart
 *
 * @brief Support class to maintain a subpart of a patch pattern in device
 *        memory. Each patch pattern subpart gives one similarity score.
 *
 */
struct DevicePatchPatternSubpart
{
    float2 coordinates[ALICEVISION_DEVICE_PATCH_MAX_COORDS_PER_SUBPARTS];  //< subpart coordinate list
    int nbCoordinates;                                                     //< subpart number of coordinate
    float level;                                                           //< subpart related mipmap level (>=0)
    float downscale;                                                       //< subpart related mipmap downscale (>=1)
    float weight;                                                          //< subpart related similarity weight in range (0, 1)
    bool isCircle;                                                         //< subpart is a circle (cast to int for alignment)
    int wsh;                                                               //< subpart half-width (full and circle)
};

/**
 * @struct DevicePatchPattern
 * @brief Support class to maintain a patch pattern in gpu constant memory.
 */
struct DevicePatchPattern
{
    DevicePatchPatternSubpart subparts[ALICEVISION_DEVICE_PATCH_MAX_SUBPARTS];  //< patch pattern subparts (one similarity per subpart)
    int nbSubparts;                                                             //< patch pattern number of subparts (>0)
};

ALICEVISION_DEPTHMAP_MTL_NS_END
