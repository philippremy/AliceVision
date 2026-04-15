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
 * @brief Convert the pixels of the given texture from RGBA to LAB in place
 * @param[out] inout_img_dmp The texture to operate on
 * @param[in] dev The device to run the operation on
 */
void MTL_rgb2lab(id<MTLTexture> inout_img_dmp, id<MTLDevice> dev);

}  // namespace aliceVision::depthMap::mtl
