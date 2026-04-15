// This file is part of the AliceVision project.
// Copyright (c) 2023 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/CustomPatchPatternParams.hpp>

#include <memory>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Build user custom patch pattern in Metal constant memory
 *
 * @param[in] patchParams The user custom patch pattern parameters
 * @param[in] dev The device to build the patch pattern parameters for
 */
void buildCustomPatchPattern(const CustomPatchPatternParams& patchParams, const std::unique_ptr<MTLDeviceImpl>& dev);

}  // namespace aliceVision::depthMap::mtl
