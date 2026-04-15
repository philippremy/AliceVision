// This file is part of the AliceVision project.
// Copyright (c) 2022, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains configurable parameters for the Depth Map computation
 * process
 */

#pragma once

#include <aliceVision/depthMap_mtl/CustomPatchPatternParams.hpp>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Depth Map Parameters
 */
struct DepthMapParams
{
    // User parameters

    int maxTCams = 10;                 //< Global T cameras maximum
    bool chooseTCamsPerTile = true;    //< Choose T cameras per R tile or for the entire R image
    bool exportTilePattern = false;    //< Export tile pattern object
    bool autoAdjustSmallImage = true;  //< Allow program to override parameters for the single tile case

    // User custom patch pattern for similarity volume computation (both SGM & Refine)
    CustomPatchPatternParams customPatchPattern;

    // Constant parameters

    const bool useRefine = true;  //< For debug purposes: enable or disable Refine computation
};

}  // namespace aliceVision::depthMap::mtl
