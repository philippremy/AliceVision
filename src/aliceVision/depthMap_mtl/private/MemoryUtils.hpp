// This file is part of the extension to AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains utility functions related to memory (RAM) on host and
 * device
 */

#pragma once

#import <Metal/MTLDevice.h>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Returns the available, used and total amount of device memory in MB
 *
 * @param[in] dev The device to query
 * @param[in, out] availableMB The available memory
 * @param[in, out] usedMB The used memory
 * @param[in, out] totalMB The total memory
 */
void getDeviceMemoryInfo(id<MTLDevice> dev, double& availableMB, double& usedMB, double& totalMB);

}  // namespace aliceVision::depthMap::mtl
