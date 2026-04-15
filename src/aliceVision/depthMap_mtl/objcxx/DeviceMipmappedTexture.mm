// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#import <aliceVision/depthMap_mtl/private/DeviceMipmappedTexture.hpp>

#import <aliceVision/depthMap_mtl/private/DeviceCommandManager.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>

#import <Foundation/NSRange.h>
#import <Metal/MTLTypes.h>
#import <Metal/MTLTexture.h>

namespace aliceVision::depthMap::mtl {

void MTL_createMipmappedArray(id<MTLTexture> inout_img_dmp, int levelCount, id<MTLDevice> dev)
{
    // initialize each mipmapped array level from level 0
    unsigned int width = inout_img_dmp.width;
    unsigned int height = inout_img_dmp.height;

    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // Create new current CMD Buffer
    cmdManager.newCMDBuffer();

    for (int level = 1; level < levelCount; ++level)
    {
        width /= 2;
        height /= 2;

        // Create a texture view for the previous level
        MTLTextureViewDescriptor* prevLevelDesc = [MTLTextureViewDescriptor new];
        prevLevelDesc.pixelFormat = inout_img_dmp.pixelFormat;
        prevLevelDesc.textureType = inout_img_dmp.textureType;
        prevLevelDesc.levelRange = NSMakeRange(level - 1, 1);
        id<MTLTexture> prevLevelTex = [inout_img_dmp newTextureViewWithDescriptor:prevLevelDesc];
        if (!prevLevelTex)
            ALICEVISION_THROW_ERROR("Failed to create texture view for previous level: " << (level - 1) << "!");

        // Create a texture view for the current level
        MTLTextureViewDescriptor* currLevelDesc = [MTLTextureViewDescriptor new];
        currLevelDesc.pixelFormat = inout_img_dmp.pixelFormat;
        currLevelDesc.textureType = inout_img_dmp.textureType;
        currLevelDesc.levelRange = NSMakeRange(level, 1);
        id<MTLTexture> currLevelTex = [inout_img_dmp newTextureViewWithDescriptor:currLevelDesc];
        if (!currLevelTex)
            ALICEVISION_THROW_ERROR("Failed to create texture view for current level: " << level << "!");

        // Enqueue
        cmdManager.newCommandEncoder()
          .setPipelineState("aliceVision::depthMap::mtl::kernel_createMipmappedArrayLevel")
          .setResource(prevLevelTex, 0) /* Input Level to sample */
          .setResource(currLevelTex, 1) /* Output Level to write */
          .setDispatchDimensions(MTLSizeMake(width, height, 1), MTLSizeMake(16, 16, 1))
          .finishCommandEncoder();
    }

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.finishCommandBuffer();

    // Await
    cmdManager.waitForFinish(cmdBuf);
}

}  // namespace aliceVision::depthMap::mtl
