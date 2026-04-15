// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#import <aliceVision/depthMap_mtl/private/DeviceColorConversion.hpp>

#import <aliceVision/depthMap_mtl/private/DeviceCommandManager.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>

#import <Metal/MTLTypes.h>
#import <Metal/MTLTexture.h>

namespace aliceVision::depthMap::mtl {

void MTL_rgb2lab(id<MTLTexture> inout_img_dmp, id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_rgb2lab")
                                    .setResource(inout_img_dmp, 0)
                                    .setDispatchDimensions(MTLSizeMake(inout_img_dmp.width, inout_img_dmp.height, 1), MTLSizeMake(32, 2, 1))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    cmdManager.waitForFinish(cmdBuf);
}

}  // namespace aliceVision::depthMap::mtl
