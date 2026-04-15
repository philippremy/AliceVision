// This file is part of the AliceVision project.
// Copyright (c) 2022 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#import <Metal/MTLDevice.h>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Log current Metal device memory information
 */
void logDeviceMemoryInfo(id<MTLDevice> forDev);

}  // namespace aliceVision::depthMap::mtl
