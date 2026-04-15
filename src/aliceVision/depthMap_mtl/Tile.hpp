// This file is part of the AliceVision project.
// Copyright (c) 2022, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This class contains the declaration of a struct representing a tile in the
 * Depth Map computation
 */

#pragma once

#include <aliceVision/mvsData/ROI.hpp>

#include <vector>
#include <ostream>

namespace aliceVision::depthMap::mtl {

/**
 * @struct Depth Map Tile Structure
 *
 * @brief Support struct to keep tile information.
 */
struct Tile
{
    int id;                        //< Tile index
    int nbTiles;                   //< Number of tiles per image
    int rc;                        //< Related R camera index
    std::vector<int> sgmTCams;     //< SGM T camera index list
    std::vector<int> refineTCams;  //< Refine T camera index list
    ROI roi;                       //< 2D region of interest of the R image
};

std::ostream& operator<<(std::ostream& os, const aliceVision::depthMap::mtl::Tile& tile);

}  // namespace aliceVision::depthMap::mtl
