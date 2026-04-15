// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains declarations of pre-defined algorithms implemented in
 * Apple Metal.
 */

#pragma once

#import <Metal/MTLTexture.h>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Create a mip level from the previous mip level
 * @param[out] inout_img_dmp The texture to operate on
 * @param[in] levelCount The level count
 * @param[in] dev The device to run the operation on
 */
void MTL_createMipmappedArray(id<MTLTexture> inout_img_dmp, int levelCount, id<MTLDevice> dev);

}  // namespace aliceVision::depthMap::mtl
