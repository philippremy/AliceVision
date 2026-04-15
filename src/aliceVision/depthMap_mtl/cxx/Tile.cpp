// This file is part of the AliceVision project.
// Copyright (c) 2022, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/Tile.hpp>

namespace aliceVision::depthMap::mtl {

std::ostream& operator<<(std::ostream& os, const aliceVision::depthMap::mtl::Tile& tile)
{
    os << "(RC: " << tile.rc << ", Tile: " << (tile.id + 1) << "/" << tile.nbTiles << ")";
    return os;
}

}  // namespace aliceVision::depthMap::mtl
