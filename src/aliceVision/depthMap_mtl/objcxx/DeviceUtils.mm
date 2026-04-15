// This file is part of the AliceVision project.
// Copyright (c) 2022, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#import <aliceVision/depthMap_mtl/private/DeviceUtils.hpp>

#import <aliceVision/depthMap_mtl/private/MemoryUtils.hpp>

#include <aliceVision/system/Logger.hpp>

#include <cstddef>
#include <iostream>

#import <Metal/MTLDevice.h>

namespace aliceVision::depthMap::mtl {

void logDeviceMemoryInfo(id<MTLDevice> forDev)
{
    double availableMB = 0.0;
    double usedMB = 0.0;
    double totalMB = 0.0;

    getDeviceMemoryInfo(forDev, availableMB, usedMB, totalMB);

    ALICEVISION_LOG_INFO("Device memory (device ID: " << [forDev registryID] << "):" << std::endl
                                                      << "\t- Used: " << usedMB << " MB" << std::endl
                                                      << "\t- Available: " << availableMB << " MB" << std::endl
                                                      << "\t- Total: " << totalMB << " MB");
}

}  // namespace aliceVision::depthMap::mtl
