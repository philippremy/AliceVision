// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#import <aliceVision/depthMap_mtl/private/DeviceDepthSimilarityMap.hpp>
#import <Metal/Metal.h>

#import <aliceVision/depthMap_mtl/private/DeviceCache.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceCommandManager.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>
#import <aliceVision/depthMap_mtl/private/KernelArgs.hpp>

#include <aliceVision/mvsData/ROI.hpp>

#import <Metal/MTLBuffer.h>
#import <Metal/MTLDevice.h>
#import <Metal/MTLTypes.h>

#import <aliceVision/depthMap_mtl/private/MTLDeviceMemoryImpl.hpp>

namespace aliceVision::depthMap::mtl {

void MTL_depthSimMapComputeNormal(const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& out_normalMap_dmp,
                                  const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_depthSimMap_dmp,
                                  const int rcDeviceCameraParamsId,
                                  const int stepXY,
                                  const ROI& roi,
                                  id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // Get the device camera params
    id<MTLBuffer> deviceCameraParams = DeviceManager::instance().getDeviceCache(dev).getCameraParams();

    // Create kernel args
    const auto kArgs = ArgsDepthSimMapComputeNormal{
      .out_normalMap_p = static_cast<int>(out_normalMap_dmp->getSize().width()),
      .in_depthSimMap_p = static_cast<int>(in_depthSimMap_dmp->getSize().width()),
      .rcDeviceCameraParamsId = rcDeviceCameraParamsId,
      .stepXY = stepXY,
      .roi = roi,
    };

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_depthSimMapComputeNormal")
                                    .setResource(out_normalMap_dmp->getMTLBuffer(), 0)
                                    .setResource(in_depthSimMap_dmp->getMTLBuffer(), 1)
                                    .setResource(deviceCameraParams, 29)
                                    .setPushConstants(kArgs, 30)
                                    .setDispatchDimensions(MTLSizeMake(roi.width(), roi.height(), 1), MTLSizeMake(8, 8, 1))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    // Await
    cmdManager.waitForFinish(cmdBuf);
}

void MTL_depthThicknessSmoothThickness(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_normalMap_dmp,
                                       const SgmParams& sgmParams,
                                       const RefineParams& refineParams,
                                       const ROI& roi,
                                       id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    const int sgmScaleStep = sgmParams.scale * sgmParams.stepXY;
    const int refineScaleStep = refineParams.scale * refineParams.stepXY;

    // min/max number of Refine samples in SGM thickness area
    const float minNbRefineSamples = 2.f;
    const float maxNbRefineSamples = std::max(sgmScaleStep / float(refineScaleStep), minNbRefineSamples);

    // min/max SGM thickness inflate factor
    const float minThicknessInflate = refineParams.halfNbDepths / maxNbRefineSamples;
    const float maxThicknessInflate = refineParams.halfNbDepths / minNbRefineSamples;

    // Create kernel args
    const auto kArgs = ArgsDepthThicknessSmoothThickness{
      .inout_depthThicknessMap_p = static_cast<const int>(out_normalMap_dmp->getSize().width()),
      .minThicknessInflate = minThicknessInflate,
      .maxThicknessInflate = maxThicknessInflate,
      .roi = roi,
    };

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_depthThicknessSmoothThickness")
                                    .setResource(out_normalMap_dmp->getMTLBuffer(), 0)
                                    .setPushConstants(kArgs)
                                    .setDispatchDimensions(MTLSizeMake(roi.width(), roi.height(), 1), MTLSizeMake(8, 8, 1))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    // Await
    cmdManager.waitForFinish(cmdBuf);
}

void MTL_computeSgmUpscaledDepthPixSizeMap(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_upscaledDepthPixSizeMap_dmp,
                                           const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_sgmDepthThicknessMap_dmp,
                                           const int rcDeviceCameraParamsId,
                                           const DeviceMipmapImage& rcDeviceMipmapImage,
                                           const RefineParams& refineParams,
                                           const ROI& roi,
                                           id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // Device Camera Params must be bound
    id<MTLBuffer> deviceCameraParams = DeviceManager::instance().getDeviceCache(dev).getCameraParams();

    // compute upscale ratio
    const MTLResourceSize<2>& out_mapDim = out_upscaledDepthPixSizeMap_dmp->getSize();
    const MTLResourceSize<2>& in_mapDim = in_sgmDepthThicknessMap_dmp->getSize();
    const float ratio = float(in_mapDim.width()) / float(out_mapDim.width());

    // get R mipmap image level and dimensions
    const float rcMipmapLevel = rcDeviceMipmapImage.getLevel(refineParams.scale);
    const MTLResourceSize<2> rcLevelDim = rcDeviceMipmapImage.getDimensions(refineParams.scale);

    if (refineParams.interpolateMiddleDepth)
    {
        const auto kArgs = ArgsComputeSgmUpscaledDepthPixSizeMap_Bilinear{
          .out_upscaledDepthPixSizeMap_p = static_cast<const int>(out_upscaledDepthPixSizeMap_dmp->getSize().width()),
          .in_sgmDepthThicknessMap_p = static_cast<const int>(in_sgmDepthThicknessMap_dmp->getSize().width()),
          .rcDeviceCameraParamsId = rcDeviceCameraParamsId,
          .rcLevelWidth = static_cast<const unsigned int>(rcLevelDim.width()),
          .rcLevelHeight = static_cast<const unsigned int>(rcLevelDim.height()),
          .rcMipmapLevel = rcMipmapLevel,
          .stepXY = refineParams.stepXY,
          .halfNbDepths = refineParams.halfNbDepths,
          .ratio = ratio,
          .roi = roi,
        };

        // Invoke
        id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                        .newCommandEncoder()
                                        .setPipelineState("aliceVision::depthMap::mtl::kernel_computeSgmUpscaledDepthPixSizeMap_Bilinear")
                                        .setResource(out_upscaledDepthPixSizeMap_dmp->getMTLBuffer(), 0)
                                        .setResource(in_sgmDepthThicknessMap_dmp->getMTLBuffer(), 1)
                                        .setResource(rcDeviceMipmapImage.getMTLTexture(), 0)
                                        .setResource(deviceCameraParams, 29)
                                        .setPushConstants(kArgs, 30)
                                        .setDispatchDimensions(MTLSizeMake(roi.width(), roi.height(), 1), MTLSizeMake(16, 16, 1))
                                        .finishCommandEncoder()
                                        .finishCommandBuffer();

        // Await
        cmdManager.waitForFinish(cmdBuf);
    }
    else
    {
        const auto kArgs = ArgsComputeSgmUpscaledDepthPixSizeMap_NearestNeighbor{
          .out_upscaledDepthPixSizeMap_p = static_cast<const int>(out_upscaledDepthPixSizeMap_dmp->getSize().width()),
          .in_sgmDepthThicknessMap_p = static_cast<const int>(in_sgmDepthThicknessMap_dmp->getSize().width()),
          .rcDeviceCameraParamsId = rcDeviceCameraParamsId,
          .rcLevelWidth = static_cast<const unsigned int>(rcLevelDim.width()),
          .rcLevelHeight = static_cast<const unsigned int>(rcLevelDim.height()),
          .rcMipmapLevel = rcMipmapLevel,
          .stepXY = refineParams.stepXY,
          .halfNbDepths = refineParams.halfNbDepths,
          .ratio = ratio,
          .roi = roi,
        };

        // Invoke
        id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                        .newCommandEncoder()
                                        .setPipelineState("aliceVision::depthMap::mtl::kernel_computeSgmUpscaledDepthPixSizeMap_NearestNeighbor")
                                        .setResource(out_upscaledDepthPixSizeMap_dmp->getMTLBuffer(), 0)
                                        .setResource(in_sgmDepthThicknessMap_dmp->getMTLBuffer(), 1)
                                        .setResource(rcDeviceMipmapImage.getMTLTexture(), 0)
                                        .setResource(deviceCameraParams, 29)
                                        .setPushConstants(kArgs, 30)
                                        .setDispatchDimensions(MTLSizeMake(roi.width(), roi.height(), 1), MTLSizeMake(16, 16, 1))
                                        .finishCommandEncoder()
                                        .finishCommandBuffer();

        // Await
        cmdManager.waitForFinish(cmdBuf);
    }
}

void MTL_normalMapUpscale(const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& out_upscaledMap_dmp,
                          const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& in_map_dmp,
                          const ROI& roi,
                          id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    const MTLResourceSize<2>& out_mapDim = out_upscaledMap_dmp->getSize();
    const MTLResourceSize<2>& in_mapDim = in_map_dmp->getSize();
    const float ratio = float(in_mapDim.width()) / float(out_mapDim.width());

    // Create kernel args
    const auto kArgs = ArgsMapUpscale_float3{
      .out_upscaledMap_p = static_cast<const int>(out_upscaledMap_dmp->getSize().width()),
      .in_map_p = static_cast<const int>(in_map_dmp->getSize().width()),
      .ratio = ratio,
      .roi = roi,
    };

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_mapUpscale_float3")
                                    .setResource(out_upscaledMap_dmp->getMTLBuffer(), 0)
                                    .setResource(in_map_dmp->getMTLBuffer(), 1)
                                    .setPushConstants(kArgs)
                                    .setDispatchDimensions(MTLSizeMake(roi.width(), roi.height(), 1), MTLSizeMake(16, 16, 1))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    // Await
    cmdManager.waitForFinish(cmdBuf);
}

void MTL_depthSimMapCopyDepthOnly(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_depthSimMap_dmp,
                                  const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_depthSimMap_dmp,
                                  float defaultSim,
                                  id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // get output map dimensions
    const MTLResourceSize<2>& depthSimMapDim = out_depthSimMap_dmp->getSize();

    const auto kArgs = ArgsDepthSimMapCopyDepthOnly{
      .out_deptSimMap_p = static_cast<const int>(out_depthSimMap_dmp->getSize().width()),
      .in_depthSimMap_p = static_cast<const int>(in_depthSimMap_dmp->getSize().width()),
      .width = static_cast<const unsigned int>(depthSimMapDim.width()),
      .height = static_cast<const unsigned int>(depthSimMapDim.height()),
      .defaultSim = defaultSim,
    };

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_depthSimMapCopyDepthOnly")
                                    .setResource(out_depthSimMap_dmp->getMTLBuffer(), 0)
                                    .setResource(in_depthSimMap_dmp->getMTLBuffer(), 1)
                                    .setPushConstants(kArgs)
                                    .setDispatchDimensions(MTLSizeMake(depthSimMapDim.width(), depthSimMapDim.height(), 1), MTLSizeMake(16, 16, 1))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    // Await
    cmdManager.waitForFinish(cmdBuf);
}

void MTL_depthSimMapOptimizeGradientDescent(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_optimizeDepthSimMap_dmp,
                                            const std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>& inout_imgVariance_dmp,
                                            const std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>& inout_tmpOptDepthMap_dmp,
                                            const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_sgmDepthPixSizeMap_dmp,
                                            const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_refineDepthSimMap_dmp,
                                            const int rcDeviceCameraParamsId,
                                            const DeviceMipmapImage& rcDeviceMipmapImage,
                                            const RefineParams& refineParams,
                                            const ROI& roi,
                                            id<MTLDevice> dev)

{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // get R mipmap image level and dimensions
    const float rcMipmapLevel = rcDeviceMipmapImage.getLevel(refineParams.scale);
    const MTLResourceSize<2> rcLevelDim = rcDeviceMipmapImage.getDimensions(refineParams.scale);

    // initialize depth/sim map optimized with SGM depth/pixSize map
    out_optimizeDepthSimMap_dmp->copyFromOtherBuffer(*in_sgmDepthPixSizeMap_dmp);

    // Get device camera params
    id<MTLBuffer> deviceCameraParams = DeviceManager::instance().getDeviceCache(dev).getCameraParams();

    // FIXME: Not await each time?

    const auto kArgs0 = ArgsOptimizeVarLofLABtoW{
      .out_varianceMap_p = static_cast<const int>(inout_imgVariance_dmp->getSize().width()),
      .rcLevelWidth = static_cast<const unsigned int>(rcLevelDim.width()),
      .rcLevelHeight = static_cast<const unsigned int>(rcLevelDim.height()),
      .rcMipmapLevel = rcMipmapLevel,
      .stepXY = refineParams.stepXY,
      .roi = roi,
    };

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_optimizeVarLofLABtoW")
                                    .setResource(inout_imgVariance_dmp->getMTLBuffer(), 0)
                                    .setResource(rcDeviceMipmapImage.getMTLTexture(), 0)
                                    .setPushConstants(kArgs0)
                                    .setDispatchDimensions(MTLSizeMake(roi.width(), roi.height(), 1), MTLSizeMake(32, 2, 1))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    // Await
    cmdManager.waitForFinish(cmdBuf);

    // Create a new command buffer for the loop
    cmdManager.newCMDBuffer();

    // Create textures from MTLBuffers
    // See: https://developer.apple.com/documentation/metal/mtlbuffer/maketexture(descriptor:offset:bytesperrow:)
    // NOTE: Memory is coherent between different MTLComputeCommandEncoders
    //       within the same MTLCommandBuffer
    MTLTextureDescriptor* texDesc_inout_imgVariance_dmp = [MTLTextureDescriptor new];
    texDesc_inout_imgVariance_dmp.pixelFormat = MTLPixelFormatR32Float;                               // A single 32-bit float component (x)
    texDesc_inout_imgVariance_dmp.textureType = MTLTextureType2D;                                     // Interpreted as a 2D texture
    texDesc_inout_imgVariance_dmp.storageMode = [inout_imgVariance_dmp->getMTLBuffer() storageMode];  // Must share storage type
    texDesc_inout_imgVariance_dmp.depth = 1;
    texDesc_inout_imgVariance_dmp.height = inout_imgVariance_dmp->getSize().height();
    texDesc_inout_imgVariance_dmp.width = inout_imgVariance_dmp->getSize().width();
    texDesc_inout_imgVariance_dmp.mipmapLevelCount = 1;
    texDesc_inout_imgVariance_dmp.sampleCount = 1;
    texDesc_inout_imgVariance_dmp.arrayLength = 1;

    MTLTextureDescriptor* texDesc_inout_tmpOptDepthMap_dmp = [MTLTextureDescriptor new];
    texDesc_inout_tmpOptDepthMap_dmp.pixelFormat = MTLPixelFormatR32Float;                                  // A single 32-bit float component (x)
    texDesc_inout_tmpOptDepthMap_dmp.textureType = MTLTextureType2D;                                        // Interpreted as a 2D texture
    texDesc_inout_tmpOptDepthMap_dmp.storageMode = [inout_tmpOptDepthMap_dmp->getMTLBuffer() storageMode];  // Must share storage type
    texDesc_inout_tmpOptDepthMap_dmp.depth = 1;
    texDesc_inout_tmpOptDepthMap_dmp.height = inout_tmpOptDepthMap_dmp->getSize().height();
    texDesc_inout_tmpOptDepthMap_dmp.width = inout_tmpOptDepthMap_dmp->getSize().width();
    texDesc_inout_tmpOptDepthMap_dmp.mipmapLevelCount = 1;
    texDesc_inout_tmpOptDepthMap_dmp.sampleCount = 1;
    texDesc_inout_tmpOptDepthMap_dmp.arrayLength = 1;

    const size_t minLinearalignment = [dev minimumLinearTextureAlignmentForPixelFormat:MTLPixelFormatR32Float];

    const size_t bytesPerRow_inout_imgVariance_dmp = inout_imgVariance_dmp->getSize().width() * sizeof(float);
    const size_t bytesPerRow_inout_tmpOptDepthMap_dmp = inout_tmpOptDepthMap_dmp->getSize().width() * sizeof(float);

    // Check that bytesPerRow satisfies minimumLinearTextureAlignmentForPixelFormat
    if (bytesPerRow_inout_imgVariance_dmp % minLinearalignment != 0)
        ALICEVISION_THROW_ERROR("Cannot create a linear MTLTexture from an MTLBuffer with "
                                << bytesPerRow_inout_imgVariance_dmp << " bytesPerRow because the minumum alignment is " << minLinearalignment
                                << " bytes and that resolves to a remainder of" << (bytesPerRow_inout_imgVariance_dmp % minLinearalignment) << "!");

    if (bytesPerRow_inout_tmpOptDepthMap_dmp % minLinearalignment != 0)
        ALICEVISION_THROW_ERROR("Cannot create a linear MTLTexture from an MTLBuffer with "
                                << bytesPerRow_inout_tmpOptDepthMap_dmp << " bytesPerRow because the minumum alignment is " << minLinearalignment
                                << " bytes and that resolves to a remainder of" << (bytesPerRow_inout_tmpOptDepthMap_dmp % minLinearalignment)
                                << "!");

    id<MTLTexture> imgVarianceTex = [inout_imgVariance_dmp->getMTLBuffer() newTextureWithDescriptor:texDesc_inout_imgVariance_dmp
                                                                                             offset:0
                                                                                        bytesPerRow:bytesPerRow_inout_imgVariance_dmp];
    id<MTLTexture> depthTex = [inout_tmpOptDepthMap_dmp->getMTLBuffer() newTextureWithDescriptor:texDesc_inout_tmpOptDepthMap_dmp
                                                                                          offset:0
                                                                                     bytesPerRow:bytesPerRow_inout_tmpOptDepthMap_dmp];

    if (!imgVarianceTex)
        ALICEVISION_THROW_ERROR("Failed to create MTLTexture from MTLBuffer for inout_imgVariance_dmp!");

    if (!depthTex)
        ALICEVISION_THROW_ERROR("Failed to create MTLTexture from MTLBuffer for inout_tmpOptDepthMap_dmp!");

    for (int iter = 0; iter < refineParams.optimizationNbIterations; ++iter)  // default nb iterations is 100
    {
        const auto kArgs1 = ArgsOptimizeGetOptDeptMapFromOptDepthSimMap{
          .out_tmpOptDepthMap_p = static_cast<const int>(inout_tmpOptDepthMap_dmp->getSize().width()),
          .in_optDepthSimMap_p = static_cast<const int>(out_optimizeDepthSimMap_dmp->getSize().width()),
          .roi = roi,
        };

        cmdManager.newCommandEncoder()
          .setPipelineState("aliceVision::depthMap::mtl::kernel_optimizeGetOptDeptMapFromOptDepthSimMap")
          .setResource(inout_tmpOptDepthMap_dmp->getMTLBuffer(), 0)
          .setResource(out_optimizeDepthSimMap_dmp->getMTLBuffer(), 1)
          .setPushConstants(kArgs1)
          .setDispatchDimensions(MTLSizeMake(roi.width(), roi.height(), 1), MTLSizeMake(16, 16, 1))
          .finishCommandEncoder();

        const auto kArgs2 = ArgsOptimizeDepthSimMap{
          .out_optimizeDepthSimMap_p = static_cast<const int>(out_optimizeDepthSimMap_dmp->getSize().width()),
          .in_sgmDepthPixSizeMap_p = static_cast<const int>(in_sgmDepthPixSizeMap_dmp->getSize().width()),
          .in_refineDepthSimMap_p = static_cast<const int>(in_refineDepthSimMap_dmp->getSize().width()),
          .rcDeviceCameraParamsId = rcDeviceCameraParamsId,
          .iter = iter,
          .roi = roi,
        };

        cmdManager.newCommandEncoder()
          .setPipelineState("aliceVision::depthMap::mtl::kernel_optimizeDepthSimMap")
          .setResource(out_optimizeDepthSimMap_dmp->getMTLBuffer(), 0)
          .setResource(in_sgmDepthPixSizeMap_dmp->getMTLBuffer(), 1)
          .setResource(in_refineDepthSimMap_dmp->getMTLBuffer(), 2)
          .setResource(imgVarianceTex, 0)
          .setResource(depthTex, 1)
          .setResource(deviceCameraParams, 29)
          .setPushConstants(kArgs2, 30)
          .setDispatchDimensions(MTLSizeMake(roi.width(), roi.height(), 1), MTLSizeMake(16, 16, 1))
          .finishCommandEncoder();
    }

    // Commit and await the command buffer
    cmdManager.waitForFinish(cmdManager.finishCommandBuffer());
}

}  // namespace aliceVision::depthMap::mtl
