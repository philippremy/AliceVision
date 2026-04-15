// This file is part of the AliceVision project.
// Copyright (c) 2021, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains configurable options for the Refine
 * computation
 */

#pragma once

namespace aliceVision::depthMap::mtl {

/**
 * @struct RefineParams
 *
 * @brief Refine Parameters
 */
struct RefineParams
{
    // User parameters

    int scale = 1;
    int stepXY = 1;
    int wsh = 3;
    int halfNbDepths = 15;
    int nbSubsamples = 10;
    int maxTCamsPerTile = 4;
    int optimizationNbIterations = 100;
    double sigma = 15.0;
    double gammaC = 15.5;
    double gammaP = 8.0;
    bool interpolateMiddleDepth = false;
    bool useConsistentScale = false;
    bool useCustomPatchPattern = false;
    bool useRefineFuse = true;
    bool useColorOptimization = true;

    // Intermediate result export parameters

    bool exportIntermediateDepthSimMaps = false;
    bool exportIntermediateNormalMaps = false;
    bool exportIntermediateCrossVolumes = false;
    bool exportIntermediateTopographicCutVolumes = false;
    bool exportIntermediateVolume9pCsv = false;

    // Constant parameters

    const bool useSgmNormalMap = false;  // for experimentation purposes
};

}  // namespace aliceVision::depthMap::mtl
