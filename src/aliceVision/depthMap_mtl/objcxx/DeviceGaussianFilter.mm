// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#import <aliceVision/depthMap_mtl/private/DeviceGaussianFilter.hpp>

#import <aliceVision/depthMap_mtl/private/DeviceCommandManager.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>
#import <aliceVision/depthMap_mtl/private/KernelArgs.hpp>

#import <Metal/MTLBuffer.h>
#import <Metal/MTLTypes.h>
#import <Metal/MTLTexture.h>

namespace aliceVision::depthMap::mtl {

void MTL_downscaleWithGaussianBlur(id<MTLTexture> out_downscaledTex, id<MTLTexture> in_imgTex, int downscale, int gaussRadius, id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // Create kernel args
    const auto kArgs = ArgsDownscaleWithGaussianBlur{.downscale = downscale, .gaussRadius = gaussRadius};

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_downscaleWithGaussianBlur")
                                    .setResource(out_downscaledTex, 0)
                                    .setResource(in_imgTex, 1)
                                    .setPushConstants(kArgs)
                                    .setDispatchDimensions(MTLSizeMake(out_downscaledTex.width, out_downscaledTex.height, 1), MTLSizeMake(32, 2, 1))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    cmdManager.waitForFinish(cmdBuf);
}

}  // namespace aliceVision::depthMap::mtl
