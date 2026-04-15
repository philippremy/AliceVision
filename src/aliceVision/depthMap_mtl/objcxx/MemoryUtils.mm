// This file is part of the extension to AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/private/MemoryUtils.hpp>

#include <cassert>

#import <Metal/MTLDevice.h>

namespace aliceVision::depthMap::mtl {

void getDeviceMemoryInfo(id<MTLDevice> dev, double& availableMB, double& usedMB, double& totalMB)
{
    NSUInteger totalMem = [dev recommendedMaxWorkingSetSize];
    NSUInteger usedMem = [dev currentAllocatedSize];
    assert(usedMem <= totalMem);
    NSUInteger availableMem = totalMem - usedMem;
    availableMB = availableMem / (1024. * 1024.);
    usedMB = usedMem / (1024. * 1024.);
    totalMB = totalMem / (1024. * 1024.);
}

}  // namespace aliceVision::depthMap::mtl
