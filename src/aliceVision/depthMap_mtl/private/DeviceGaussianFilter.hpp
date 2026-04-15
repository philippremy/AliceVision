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

#import <Metal/MTLBuffer.h>
#import <Metal/MTLTexture.h>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Downscale The given image with Gaussian blur
 * @param[out] out_downscaledTex The downscaled image in device memory
 * @param[in] in_imgTex The input full size texture
 * @param[in] downscale The downscale factor to apply
 * @param[in] gaussRadius The Gaussian radius
 * @param[in] dev The device to run the operation on
 */
void MTL_downscaleWithGaussianBlur(id<MTLTexture> out_downscaledTex, id<MTLTexture> in_imgTex, int downscale, int gaussRadius, id<MTLDevice> dev);

}  // namespace aliceVision::depthMap::mtl
