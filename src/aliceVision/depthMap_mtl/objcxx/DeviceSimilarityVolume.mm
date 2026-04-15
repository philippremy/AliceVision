// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#import <aliceVision/depthMap_mtl/private/DeviceSimilarityVolume.hpp>

#import <aliceVision/depthMap_mtl/private/DeviceCache.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceCommandManager.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>
#import <aliceVision/depthMap_mtl/private/KernelArgs.hpp>

#include <functional>

#import <Metal/MTLBuffer.h>
#import <Metal/MTLTypes.h>

#import <aliceVision/depthMap_mtl/private/MTLDeviceMemoryImpl.hpp>

namespace aliceVision::depthMap::mtl {

void MTL_volumeInitTSim(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& inout_volume_dmp, TSim value, id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    MTLResourceSize<3> volDim = inout_volume_dmp->getSize();

    // Create kernel args
    // FIXME: Can be simplified to only volDimX and volDimY, because MTLBuffers
    //        are tightly packed
    const auto kArgs = ArgsVolumeInit_TSim{
      .inout_volume_s = static_cast<const int>((volDim.width() * volDim.height())),
      .inout_volume_p = static_cast<const int>(volDim.width()),
      .volDimX = static_cast<const unsigned int>(volDim.width()),
      .volDimY = static_cast<const unsigned int>(volDim.height()),
      .value = value,
    };

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeInit_TSim")
                                    .setResource(inout_volume_dmp->getMTLBuffer(), 0)
                                    .setPushConstants(kArgs)
                                    .setDispatchDimensions(MTLSizeMake(volDim.width(), volDim.height(), volDim.depth()), MTLSizeMake(32, 4, 1))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    cmdManager.waitForFinish(cmdBuf);
}

void MTL_volumeInitTSimRefine(const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::DeviceOnly>>& inout_volume_dmp,
                              TSimRefine value,
                              id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    MTLResourceSize<3> volDim = inout_volume_dmp->getSize();

    // Create kernel args
    // FIXME: Can be simplified to only volDimX and volDimY, because MTLBuffers
    //        are tightly packed
    const auto kArgs = ArgsVolumeInit_TSimRefine{
      .inout_volume_s = static_cast<const int>((volDim.width() * volDim.height())),
      .inout_volume_p = static_cast<const int>(volDim.width()),
      .volDimX = static_cast<const unsigned int>(volDim.width()),
      .volDimY = static_cast<const unsigned int>(volDim.height()),
      .value = value,
    };

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeInit_TSimRefine")
                                    .setResource(inout_volume_dmp->getMTLBuffer(), 0)
                                    .setPushConstants(kArgs)
                                    .setDispatchDimensions(MTLSizeMake(volDim.width(), volDim.height(), volDim.depth()), MTLSizeMake(32, 4, 1))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    cmdManager.waitForFinish(cmdBuf);
}

void MTL_volumeComputeSimilarity(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& out_volBestSim_dmp,
                                 const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& out_volSecBestSim_dmp,
                                 const std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>& in_depths_dmp,
                                 const int rcDeviceCameraParamsId,
                                 const int tcDeviceCameraParamsId,
                                 const DeviceMipmapImage& rcDeviceMipmapImage,
                                 const DeviceMipmapImage& tcDeviceMipmapImage,
                                 const SgmParams& sgmParams,
                                 const Range& depthRange,
                                 const ROI& roi,
                                 id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // Get device camera params
    id<MTLBuffer> deviceCameraParams = DeviceManager::instance().getDeviceCache(dev).getCameraParams();
    const auto& customPatchPattern = DeviceManager::instance().getDeviceCache(dev).getCustomPatchPattern();

    // get mipmap images level and dimensions
    const float rcMipmapLevel = rcDeviceMipmapImage.getLevel(sgmParams.scale);
    const MTLResourceSize<2> rcLevelDim = rcDeviceMipmapImage.getDimensions(sgmParams.scale);
    const MTLResourceSize<2> tcLevelDim = tcDeviceMipmapImage.getDimensions(sgmParams.scale);

    const auto kArgs = ArgsVolumeComputeSimilarity{
      .out_volume1st_s = static_cast<const int>(out_volBestSim_dmp->getSize().width() * out_volBestSim_dmp->getSize().height()),
      .out_volume1st_p = static_cast<const int>(out_volBestSim_dmp->getSize().width()),
      .out_volume2nd_s = static_cast<const int>(out_volSecBestSim_dmp->getSize().width() * out_volSecBestSim_dmp->getSize().height()),
      .out_volume2nd_p = static_cast<const int>(out_volSecBestSim_dmp->getSize().width()),
      .in_depths_p = static_cast<const int>(in_depths_dmp->getSize().width()),
      .rcDeviceCameraParamsId = rcDeviceCameraParamsId,
      .tcDeviceCameraParamsId = tcDeviceCameraParamsId,
      .rcSgmLevelWidth = static_cast<const unsigned int>(rcLevelDim.width()),
      .rcSgmLevelHeight = static_cast<const unsigned int>(rcLevelDim.height()),
      .tcSgmLevelWidth = static_cast<const unsigned int>(tcLevelDim.width()),
      .tcSgmLevelHeight = static_cast<const unsigned int>(tcLevelDim.height()),
      .rcMipmapLevel = rcMipmapLevel,
      .stepXY = sgmParams.stepXY,
      .wsh = sgmParams.wsh,
      .invGammaC = (1.f / float(sgmParams.gammaC)),
      .invGammaP = (1.f / float(sgmParams.gammaP)),
      .useConsistentScale = sgmParams.useConsistentScale,
      .useCustomPatchPattern = sgmParams.useCustomPatchPattern,
      .depthRange = depthRange,
      .roi = roi,
    };

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeComputeSimilarity")
                                    .setResource(out_volBestSim_dmp->getMTLBuffer(), 0)
                                    .setResource(out_volSecBestSim_dmp->getMTLBuffer(), 1)
                                    .setResource(in_depths_dmp->getMTLBuffer(), 2)
                                    .setResource(rcDeviceMipmapImage.getMTLTexture(), 0)
                                    .setResource(tcDeviceMipmapImage.getMTLTexture(), 1)
                                    .setResource(deviceCameraParams, 28)
                                    .setPushConstants(customPatchPattern, 29)
                                    .setPushConstants(kArgs, 30)
                                    .setDispatchDimensionsWithAutomaticThreadgroupSize(MTLSizeMake(roi.width(), roi.height(), depthRange.size()))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    // Await
    cmdManager.waitForFinish(cmdBuf);
}

void MTL_volumeUpdateUninitializedSimilarity(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& in_volBestSim_dmp,
                                             const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& inout_volSecBestSim_dmp,
                                             id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    assert(in_volBestSim_dmp->getSize() == inout_volSecBestSim_dmp->getSize());

    // get input/output volume dimensions
    const MTLResourceSize<3>& volDim = inout_volSecBestSim_dmp->getSize();

    const auto kArgs = ArgsVolumeUpdateUninitialized{
      .inout_volume2nd_s = static_cast<const int>(inout_volSecBestSim_dmp->getSize().width() * inout_volSecBestSim_dmp->getSize().height()),
      .inout_volume2nd_p = static_cast<const int>(inout_volSecBestSim_dmp->getSize().width()),
      .in_volume1st_s = static_cast<const int>(in_volBestSim_dmp->getSize().width() * in_volBestSim_dmp->getSize().height()),
      .in_volume1st_p = static_cast<const int>(in_volBestSim_dmp->getSize().width()),
      .volDimX = static_cast<const unsigned int>(volDim.width()),
      .volDimY = static_cast<const unsigned int>(volDim.height()),
    };

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeUpdateUninitialized")
                                    .setResource(inout_volSecBestSim_dmp->getMTLBuffer(), 0)
                                    .setResource(in_volBestSim_dmp->getMTLBuffer(), 1)
                                    .setPushConstants(kArgs, 30)
                                    .setDispatchDimensionsWithAutomaticThreadgroupSize(MTLSizeMake(volDim.width(), volDim.height(), volDim.depth()))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    // Await
    cmdManager.waitForFinish(cmdBuf);
}

// WARN: This function should *not* create a new MTLCommandBuffer, because it
//       will be called in a loop!
void MTL_volumeAggregatePath(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& out_volAgr_dmp,
                             const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>& inout_volSliceAccA_dmp,
                             const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>& inout_volSliceAccB_dmp,
                             const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>& inout_volAxisAcc_dmp,
                             const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& in_volSim_dmp,
                             const DeviceMipmapImage& rcDeviceMipmapImage,
                             const MTLResourceSize<2>& rcLevelDim,
                             const float rcMipmapLevel,
                             const MTLResourceSize<3>& axisT,
                             const SgmParams& sgmParams,
                             const int lastDepthIndex,
                             const int filteringIndex,
                             const bool invY,
                             const ROI& roi,
                             id<MTLDevice> dev)
{
    MTLResourceSize<3> volDim = in_volSim_dmp->getSize();
    volDim.depth() = lastDepthIndex;  // override volume depth, use rc depth list last index

    size_t volDimX;
    size_t volDimY;
    size_t volDimZ;

    switch (axisT.width())
    {
        case 0:
            volDimX = volDim.width();
            break;
        case 1:
            volDimX = volDim.height();
            break;
        case 2:
            volDimX = volDim.depth();
            break;
        default:
            ALICEVISION_THROW_ERROR("Unknown Axis: " << axisT.width());
    }

    switch (axisT.height())
    {
        case 0:
            volDimY = volDim.width();
            break;
        case 1:
            volDimY = volDim.height();
            break;
        case 2:
            volDimY = volDim.depth();
            break;
        default:
            ALICEVISION_THROW_ERROR("Unknown Axis: " << axisT.height());
    }

    switch (axisT.depth())
    {
        case 0:
            volDimZ = volDim.width();
            break;
        case 1:
            volDimZ = volDim.height();
            break;
        case 2:
            volDimZ = volDim.depth();
            break;
        default:
            ALICEVISION_THROW_ERROR("Unknown Axis: " << axisT.depth());
    }

    const int3 volDim_ = int3{static_cast<int>(volDim.width()), static_cast<int>(volDim.height()), static_cast<int>(volDim.depth())};
    const int3 axisT_ = int3{static_cast<int>(axisT.width()), static_cast<int>(axisT.height()), static_cast<int>(axisT.depth())};
    const int ySign = (invY ? -1 : 1);

    // setup block and grid
    const int blockSize = 8;
    const MTLSize blockVolXZ = MTLSizeMake(blockSize, blockSize, 1);
    const MTLSize gridVolXZ = MTLSizeMake(volDimX, volDimZ, 1);

    const int blockSizeL = 64;
    const MTLSize blockColZ = MTLSizeMake(blockSizeL, 1, 1);
    const MTLSize gridColZ = MTLSizeMake(volDimX, 1, 1);

    const MTLSize blockVolSlide = MTLSizeMake(blockSizeL, 1, 1);
    const MTLSize gridVolSlide = MTLSizeMake(volDimX, volDimZ, 1);

    const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>* xzSliceForY_dmpPtr = &inout_volSliceAccA_dmp;    // Y slice
    const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>* xzSliceForYm1_dmpPtr = &inout_volSliceAccB_dmp;  // Y-1 slice
    const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>* bestSimInYm1_dmpPtr =
      &inout_volAxisAcc_dmp;  // best sim score along the Y axis for each Z value

    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    const auto kArgs0 = ArgsVolumeGetVolumeXZSliceTSimTSimAcc{
      .slice_p = static_cast<const int>((*xzSliceForYm1_dmpPtr)->getSize().width()),
      .volume_s = static_cast<const int>(in_volSim_dmp->getSize().width() * in_volSim_dmp->getSize().height()),
      .volume_p = static_cast<const int>(in_volSim_dmp->getSize().width()),
      .volDim = volDim_,
      .axisT = axisT_,
      .y = 0,
    };

    // Invoke
    cmdManager.newCommandEncoder()
      .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeGetVolumeXZSlice_TSimTSimAcc")
      .setResource((*xzSliceForYm1_dmpPtr)->getMTLBuffer(), 0)
      .setResource(in_volSim_dmp->getMTLBuffer(), 1)
      .setPushConstants(kArgs0)
      .setDispatchDimensions(gridVolXZ, blockVolXZ)
      .finishCommandEncoder();

    const auto kArgs1 = ArgsVolumeInitVolumeYSlice_TSim{
      .volume_s = static_cast<const int>(out_volAgr_dmp->getSize().width() * out_volAgr_dmp->getSize().height()),
      .volume_p = static_cast<const int>(out_volAgr_dmp->getSize().width()),
      .volDim = volDim_,
      .axisT = axisT_,
      .y = 0,
      .cst = 255,
    };

    // Invoke
    cmdManager.newCommandEncoder()
      .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeInitVolumeYSlice_TSim")
      .setResource(out_volAgr_dmp->getMTLBuffer(), 0)
      .setPushConstants(kArgs1)
      .setDispatchDimensions(gridVolXZ, blockVolXZ)
      .finishCommandEncoder();

    for (int iy = 1; iy < volDimY; ++iy)
    {
        const int y = invY ? volDimY - 1 - iy : iy;

        // For each column: compute the best score
        // Foreach x:
        //   bestSimInYm1[x] = min(d_xzSliceForY[1:height])
        const auto kArgs2 = ArgsVolumeComputeBestZInSlice{.xzSlice_p = static_cast<const int>((*xzSliceForYm1_dmpPtr)->getSize().width()),
                                                          .volDimX = static_cast<const int>(volDimX),
                                                          .volDimZ = static_cast<const int>(volDimZ)};

        // Invoke
        cmdManager.newCommandEncoder()
          .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeComputeBestZInSlice")
          .setResource((*xzSliceForYm1_dmpPtr)->getMTLBuffer(), 0)
          .setResource((*bestSimInYm1_dmpPtr)->getMTLBuffer(), 1)
          .setPushConstants(kArgs2)
          .setDispatchDimensions(gridColZ, blockColZ)
          .finishCommandEncoder();

        // Copy the 'z' plane from 'in_volSim_dmp' into 'xzSliceForY'
        const auto kArgs3 = ArgsVolumeGetVolumeXZSlice_TSimAccTSim{
          .slice_p = static_cast<const int>((*xzSliceForY_dmpPtr)->getSize().width()),
          .volume_s = static_cast<const int>(in_volSim_dmp->getSize().width() * in_volSim_dmp->getSize().height()),
          .volume_p = static_cast<const int>(in_volSim_dmp->getSize().width()),
          .volDim = volDim_,
          .axisT = axisT_,
          .y = y,
        };

        // Invoke
        cmdManager.newCommandEncoder()
          .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeGetVolumeXZSlice_TSimAccTSim")
          .setResource((*xzSliceForY_dmpPtr)->getMTLBuffer(), 0)
          .setResource(in_volSim_dmp->getMTLBuffer(), 1)
          .setPushConstants(kArgs3)
          .setDispatchDimensions(gridVolXZ, blockVolXZ)
          .finishCommandEncoder();

        const auto kArgs4 = ArgsVolumeAggregateCostVolumeAtXInSlices{
          .rcSgmLevelWidth = static_cast<const unsigned int>(rcLevelDim.width()),
          .rcSgmLevelHeight = static_cast<const unsigned int>(rcLevelDim.height()),
          .rcMipmapLevel = rcMipmapLevel,
          .xzSliceForY_p = static_cast<const int>((*xzSliceForY_dmpPtr)->getSize().width()),
          .xzSliceForYm1_p = static_cast<const int>((*xzSliceForYm1_dmpPtr)->getSize().width()),
          .volAgr_s = static_cast<const int>(out_volAgr_dmp->getSize().width() * out_volAgr_dmp->getSize().height()),
          .volAgr_p = static_cast<const int>(out_volAgr_dmp->getSize().width()),
          .volDim = volDim_,
          .axisT = axisT_,
          .step = static_cast<const float>(sgmParams.stepXY),
          .y = y,
          .P1 = static_cast<const float>(sgmParams.p1),
          ._P2 = static_cast<const float>(sgmParams.p2Weighting),
          .ySign = ySign,
          .filteringIndex = filteringIndex,
          .roi = roi,
        };

        // Invoke
        cmdManager.newCommandEncoder()
          .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeAggregateCostVolumeAtXInSlices")
          .setResource(rcDeviceMipmapImage.getMTLTexture(), 0)
          .setResource((*xzSliceForY_dmpPtr)->getMTLBuffer(), 0)
          .setResource((*xzSliceForYm1_dmpPtr)->getMTLBuffer(), 1)
          .setResource((*bestSimInYm1_dmpPtr)->getMTLBuffer(), 2)
          .setResource(out_volAgr_dmp->getMTLBuffer(), 3)
          .setPushConstants(kArgs4)
          .setDispatchDimensions(gridVolSlide, blockVolSlide)
          .finishCommandEncoder();

        std::swap(xzSliceForYm1_dmpPtr, xzSliceForY_dmpPtr);
    }
}

void MTL_volumeOptimize(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& out_volSimFiltered_dmp,
                        const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>& inout_volSliceAccA_dmp,
                        const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>& inout_volSliceAccB_dmp,
                        const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>& inout_volAxisAcc_dmp,
                        const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& in_volSim_dmp,
                        const DeviceMipmapImage& rcDeviceMipmapImage,
                        const SgmParams& sgmParams,
                        const int lastDepthIndex,
                        const ROI& roi,
                        id<MTLDevice> dev)
{
    // get R mipmap image level and dimensions
    const float rcMipmapLevel = rcDeviceMipmapImage.getLevel(sgmParams.scale);
    const MTLResourceSize<2> rcLevelDim = rcDeviceMipmapImage.getDimensions(sgmParams.scale);

    // NOTE: New MTLCommandBuffer for loop starts here
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);
    cmdManager.newCMDBuffer();

    // update aggregation volume
    int npaths = 0;
    const std::function<void(const MTLResourceSize<3>&, bool)> updateAggrVolume = [&](const MTLResourceSize<3>& axisT, bool invX) {
        MTL_volumeAggregatePath(out_volSimFiltered_dmp,
                                inout_volSliceAccA_dmp,
                                inout_volSliceAccB_dmp,
                                inout_volAxisAcc_dmp,
                                in_volSim_dmp,
                                rcDeviceMipmapImage,
                                rcLevelDim,
                                rcMipmapLevel,
                                axisT,
                                sgmParams,
                                lastDepthIndex,
                                npaths,
                                invX,
                                roi,
                                dev);
        npaths++;
    };

    // filtering is done on the last axis
    const std::map<char, MTLResourceSize<3>> mapAxes = {
      {'X', {1, 0, 2}},  // XYZ -> YXZ
      {'Y', {0, 1, 2}},  // XYZ
    };

    const char filteringAxes[2] = {'Y', 'X'};
    for (char axis : filteringAxes)
    {
        const MTLResourceSize<3>& axisT = mapAxes.at(axis);
        updateAggrVolume(axisT, false);  // without transpose
        updateAggrVolume(axisT, true);   // with transpose of the last axis
    }

    // Finish the MTLCommandBuffer from above and await it
    cmdManager.waitForFinish(cmdManager.finishCommandBuffer());
}

void MTL_volumeRetrieveBestDepth(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_sgmDepthThicknessMap_dmp,
                                 const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_sgmDepthSimMap_dmp,
                                 const bool computeDepthSimMap,
                                 const std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>& in_depths_dmp,
                                 const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& in_volSim_dmp,
                                 const int rcDeviceCameraParamsId,
                                 const SgmParams& sgmParams,
                                 const Range& depthRange,
                                 const ROI& roi,
                                 id<MTLDevice> dev)
{
    // We will switch between two kernels depening on whether the depth sim map
    // should be used

    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // Get device camera params
    id<MTLBuffer> deviceCameraParams = DeviceManager::instance().getDeviceCache(dev).getCameraParams();

    // constant kernel inputs
    const int scaleStep = sgmParams.scale * sgmParams.stepXY;
    const float thicknessMultFactor = 1.f + float(sgmParams.depthThicknessInflate);
    const float maxSimilarity = float(sgmParams.maxSimilarity) * 254.f;  // convert from (0, 1) to (0, 254)

    if (computeDepthSimMap)
    {
        const auto kArgs = ArgsVolumeRetrieveBestDepth_DepthSimMap{
          .out_sgmDepthThicknessMap_p = static_cast<const int>(out_sgmDepthThicknessMap_dmp->getSize().width()),
          .out_sgmDepthSimMap_p = static_cast<const int>(out_sgmDepthSimMap_dmp->getSize().width()),
          .in_depths_p = static_cast<const int>(in_depths_dmp->getSize().width()),
          .in_volSim_s = static_cast<const int>(in_volSim_dmp->getSize().width() * in_volSim_dmp->getSize().height()),
          .in_volSim_p = static_cast<const int>(in_volSim_dmp->getSize().width()),
          .rcDeviceCameraParamsId = rcDeviceCameraParamsId,
          .volDimZ = static_cast<const int>(in_volSim_dmp->getSize().depth()),
          .scaleStep = scaleStep,
          .thicknessMultFactor = thicknessMultFactor,
          .maxSimilarity = maxSimilarity,
          .depthRange = depthRange,
          .roi = roi,
        };

        // Invoke
        id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                        .newCommandEncoder()
                                        .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeRetrieveBestDepth_DepthSimMap")
                                        .setResource(out_sgmDepthThicknessMap_dmp->getMTLBuffer(), 0)
                                        .setResource(out_sgmDepthSimMap_dmp->getMTLBuffer(), 1)
                                        .setResource(in_depths_dmp->getMTLBuffer(), 2)
                                        .setResource(in_volSim_dmp->getMTLBuffer(), 3)
                                        .setResource(deviceCameraParams, 29)
                                        .setPushConstants(kArgs, 30)
                                        .setDispatchDimensionsWithAutomaticThreadgroupSize(MTLSizeMake(roi.width(), roi.height(), 1))
                                        .finishCommandEncoder()
                                        .finishCommandBuffer();

        // Await
        cmdManager.waitForFinish(cmdBuf);
    }
    else
    {
        const auto kArgs = ArgsVolumeRetrieveBestDepth_NoDepthSimMap{
          .out_sgmDepthThicknessMap_p = static_cast<const int>(out_sgmDepthThicknessMap_dmp->getSize().width()),
          .in_depths_p = static_cast<const int>(in_depths_dmp->getSize().width()),
          .in_volSim_s = static_cast<const int>(in_volSim_dmp->getSize().width() * in_volSim_dmp->getSize().height()),
          .in_volSim_p = static_cast<const int>(in_volSim_dmp->getSize().width()),
          .rcDeviceCameraParamsId = rcDeviceCameraParamsId,
          .volDimZ = static_cast<const int>(in_volSim_dmp->getSize().depth()),
          .scaleStep = scaleStep,
          .thicknessMultFactor = thicknessMultFactor,
          .maxSimilarity = maxSimilarity,
          .depthRange = depthRange,
          .roi = roi,
        };

        // Invoke
        id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                        .newCommandEncoder()
                                        .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeRetrieveBestDepth_NoDepthSimMap")
                                        .setResource(out_sgmDepthThicknessMap_dmp->getMTLBuffer(), 0)
                                        .setResource(in_depths_dmp->getMTLBuffer(), 1)
                                        .setResource(in_volSim_dmp->getMTLBuffer(), 2)
                                        .setResource(deviceCameraParams, 29)
                                        .setPushConstants(kArgs, 30)
                                        .setDispatchDimensionsWithAutomaticThreadgroupSize(MTLSizeMake(roi.width(), roi.height(), 1))
                                        .finishCommandEncoder()
                                        .finishCommandBuffer();

        // Await
        cmdManager.waitForFinish(cmdBuf);
    }
}

void MTL_volumeRefineSimilarity(const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::DeviceOnly>>& inout_volSim_dmp,
                                const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_sgmDepthPixSizeMap_dmp,
                                const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& in_sgmNormalMap_dmpPtr,
                                bool useSgmNormalMap,
                                const int rcDeviceCameraParamsId,
                                const int tcDeviceCameraParamsId,
                                const DeviceMipmapImage& rcDeviceMipmapImage,
                                const DeviceMipmapImage& tcDeviceMipmapImage,
                                const RefineParams& refineParams,
                                const Range& depthRange,
                                const ROI& roi,
                                id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // Device Camera Params and Patch Pattern
    id<MTLBuffer> deviceCameraParams = DeviceManager::instance().getDeviceCache(dev).getCameraParams();
    const DevicePatchPattern& devicePatchPattern = DeviceManager::instance().getDeviceCache(dev).getCustomPatchPattern();

    // get mipmap images level and dimensions
    const float rcMipmapLevel = rcDeviceMipmapImage.getLevel(refineParams.scale);
    const MTLResourceSize<2> rcLevelDim = rcDeviceMipmapImage.getDimensions(refineParams.scale);
    const MTLResourceSize<2> tcLevelDim = tcDeviceMipmapImage.getDimensions(refineParams.scale);

    if (useSgmNormalMap)
    {
        const auto kArgs = ArgsVolumeRefineSimilarity_SgmNormalMap{
          .inout_volSim_s = static_cast<const int>(inout_volSim_dmp->getSize().width() * inout_volSim_dmp->getSize().height()),
          .inout_volSim_p = static_cast<const int>(inout_volSim_dmp->getSize().width()),
          .in_sgmDepthPixSizeMap_p = static_cast<const int>(in_sgmDepthPixSizeMap_dmp->getSize().width()),
          .in_sgmNormalMap_p = static_cast<const int>(in_sgmNormalMap_dmpPtr->getSize().width()),
          .rcDeviceCameraParamsId = rcDeviceCameraParamsId,
          .tcDeviceCameraParamsId = tcDeviceCameraParamsId,
          .rcRefineLevelWidth = static_cast<const unsigned int>(rcLevelDim.width()),
          .rcRefineLevelHeight = static_cast<const unsigned int>(rcLevelDim.height()),
          .tcRefineLevelWidth = static_cast<const unsigned int>(tcLevelDim.width()),
          .tcRefineLevelHeight = static_cast<const unsigned int>(tcLevelDim.height()),
          .rcMipmapLevel = rcMipmapLevel,
          .volDimZ = static_cast<const int>(inout_volSim_dmp->getSize().depth()),
          .stepXY = refineParams.stepXY,
          .wsh = refineParams.wsh,
          .invGammaC = (1.f / float(refineParams.gammaC)),
          .invGammaP = (1.f / float(refineParams.gammaP)),
          .useConsistentScale = refineParams.useConsistentScale,
          .useCustomPatchPattern = refineParams.useCustomPatchPattern,
          .depthRange = depthRange,
          .roi = roi,
        };

        // Invoke
        id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                        .newCommandEncoder()
                                        .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeRefineSimilarity_SgmNormalMap")
                                        .setResource(inout_volSim_dmp->getMTLBuffer(), 0)
                                        .setResource(in_sgmDepthPixSizeMap_dmp->getMTLBuffer(), 1)
                                        .setResource(in_sgmNormalMap_dmpPtr->getMTLBuffer(), 2)
                                        .setResource(rcDeviceMipmapImage.getMTLTexture(), 0)
                                        .setResource(tcDeviceMipmapImage.getMTLTexture(), 1)
                                        .setResource(deviceCameraParams, 28)
                                        .setPushConstants(devicePatchPattern, 29)
                                        .setPushConstants(kArgs, 30)
                                        .setDispatchDimensionsWithAutomaticThreadgroupSize(MTLSizeMake(roi.width(), roi.height(), depthRange.size()))
                                        .finishCommandEncoder()
                                        .finishCommandBuffer();

        // Await
        cmdManager.waitForFinish(cmdBuf);
    }
    else
    {
        const auto kArgs = ArgsVolumeRefineSimilarity_NoSgmNormalMap{
          .inout_volSim_s = static_cast<const int>(inout_volSim_dmp->getSize().width() * inout_volSim_dmp->getSize().height()),
          .inout_volSim_p = static_cast<const int>(inout_volSim_dmp->getSize().width()),
          .in_sgmDepthPixSizeMap_p = static_cast<const int>(in_sgmDepthPixSizeMap_dmp->getSize().width()),
          .rcDeviceCameraParamsId = rcDeviceCameraParamsId,
          .tcDeviceCameraParamsId = tcDeviceCameraParamsId,
          .rcRefineLevelWidth = static_cast<const unsigned int>(rcLevelDim.width()),
          .rcRefineLevelHeight = static_cast<const unsigned int>(rcLevelDim.height()),
          .tcRefineLevelWidth = static_cast<const unsigned int>(tcLevelDim.width()),
          .tcRefineLevelHeight = static_cast<const unsigned int>(tcLevelDim.height()),
          .rcMipmapLevel = rcMipmapLevel,
          .volDimZ = static_cast<const int>(inout_volSim_dmp->getSize().depth()),
          .stepXY = refineParams.stepXY,
          .wsh = refineParams.wsh,
          .invGammaC = (1.f / float(refineParams.gammaC)),
          .invGammaP = (1.f / float(refineParams.gammaP)),
          .useConsistentScale = refineParams.useConsistentScale,
          .useCustomPatchPattern = refineParams.useCustomPatchPattern,
          .depthRange = depthRange,
          .roi = roi,
        };

        // Invoke
        id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                        .newCommandEncoder()
                                        .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeRefineSimilarity_NoSgmNormalMap")
                                        .setResource(inout_volSim_dmp->getMTLBuffer(), 0)
                                        .setResource(in_sgmDepthPixSizeMap_dmp->getMTLBuffer(), 1)
                                        .setResource(rcDeviceMipmapImage.getMTLTexture(), 0)
                                        .setResource(tcDeviceMipmapImage.getMTLTexture(), 1)
                                        .setResource(deviceCameraParams, 28)
                                        .setPushConstants(devicePatchPattern, 29)
                                        .setPushConstants(kArgs, 30)
                                        .setDispatchDimensionsWithAutomaticThreadgroupSize(MTLSizeMake(roi.width(), roi.height(), depthRange.size()))
                                        .finishCommandEncoder()
                                        .finishCommandBuffer();

        // Await
        cmdManager.waitForFinish(cmdBuf);
    }
}

void MTL_volumeRefineBestDepth(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_refineDepthSimMap_dmp,
                               const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_sgmDepthPixSizeMap_dmp,
                               const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::DeviceOnly>>& in_volSim_dmp,
                               const RefineParams& refineParams,
                               const ROI& roi,
                               id<MTLDevice> dev)
{
    // Get the command manager
    DeviceCommandManager& cmdManager = DeviceManager::instance().getCMDManager(dev);

    // constant kernel inputs
    const int halfNbSamples = refineParams.nbSubsamples * refineParams.halfNbDepths;
    const float twoTimesSigmaPowerTwo = float(2.0 * refineParams.sigma * refineParams.sigma);

    const auto kArgs = ArgsVolumeRefineBestDepth{
      .out_refineDepthSimMap_p = static_cast<const int>(out_refineDepthSimMap_dmp->getSize().width()),
      .in_sgmDepthPixSizeMap_p = static_cast<const int>(in_sgmDepthPixSizeMap_dmp->getSize().width()),
      .in_volSim_s = static_cast<const int>(in_volSim_dmp->getSize().width() * in_volSim_dmp->getSize().height()),
      .in_volSim_p = static_cast<const int>(in_volSim_dmp->getSize().width()),
      .volDimZ = static_cast<const int>(in_volSim_dmp->getSize().depth()),
      .samplesPerPixSize = refineParams.nbSubsamples,
      .halfNbSamples = halfNbSamples,
      .halfNbDepths = refineParams.halfNbDepths,
      .twoTimesSigmaPowerTwo = twoTimesSigmaPowerTwo,
      .roi = roi,
    };

    // Invoke
    id<MTLCommandBuffer> cmdBuf = cmdManager.newCMDBuffer()
                                    .newCommandEncoder()
                                    .setPipelineState("aliceVision::depthMap::mtl::kernel_volumeRefineBestDepth")
                                    .setResource(out_refineDepthSimMap_dmp->getMTLBuffer(), 0)
                                    .setResource(in_sgmDepthPixSizeMap_dmp->getMTLBuffer(), 1)
                                    .setResource(in_volSim_dmp->getMTLBuffer(), 2)
                                    .setPushConstants(kArgs, 30)
                                    .setDispatchDimensionsWithAutomaticThreadgroupSize(MTLSizeMake(roi.width(), roi.height(), 1))
                                    .finishCommandEncoder()
                                    .finishCommandBuffer();

    // Await
    cmdManager.waitForFinish(cmdBuf);
}

}  // namespace aliceVision::depthMap::mtl
