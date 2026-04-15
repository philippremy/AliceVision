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

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/RefineParams.hpp>
#include <aliceVision/depthMap_mtl/SgmParams.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/depthMap_mtl/private/DeviceMipmapImage.hpp>

#include <aliceVision/mvsData/ROI.hpp>

#import <Metal/MTLDevice.h>
#import <Metal/MTLBuffer.h>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Compute the normal map from the depth/sim map (only depth is used)
 * @param[out] out_normalMap_dmp The output normal map
 * @param[in] in_depthSimMap_dmp The input depth/sim map (only depth is used)
 * @param[in] rcDeviceCameraParamsId The R camera parameters id for array in
 *            device constant memory
 * @param[in] stepXY The input depth/sim map stepXY factor
 * @param[in] roi The 2D region of interest
 * @param[in] dev The device to operate on
 */
void MTL_depthSimMapComputeNormal(const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& out_normalMap_dmp,
                                  const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_depthSimMap_dmp,
                                  const int rcDeviceCameraParamsId,
                                  const int stepXY,
                                  const ROI& roi,
                                  id<MTLDevice> dev);

/**
 * @brief Smooth thickness map with adjacent pixels
 * @param[in,out] inout_depthThicknessMap_dmp The depth/thickness map
 * @param[in] sgmParams The Semi Global Matching parameters
 * @param[in] refineParams The Refine parameters
 * @param[in] roi The 2D region of interest
 * @param[in] dev The device to operate on
 */
void MTL_depthThicknessSmoothThickness(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_normalMap_dmp,
                                       const SgmParams& sgmParams,
                                       const RefineParams& refineParams,
                                       const ROI& roi,
                                       id<MTLDevice> dev);

/**
 * @brief Upscale the given depth/thickness map, filter masked pixels and compute pixSize from thickness
 * @param[out] out_upscaledDepthPixSizeMap_dmp The output upscaled depth/pixSize map
 * @param[in] in_sgmDepthThicknessMap_dmp The input SGM depth/thickness map
 * @param[in] rcDeviceCameraParamsId The R camera parameters id for array in device constant memory
 * @param[in] rcDeviceMipmapImage The R mipmap image in device memory container
 * @param[in] refineParams The Refine parameters
 * @param[in] roi The 2D region of interest
 * @param[in] dev The device to operate on
 */
void MTL_computeSgmUpscaledDepthPixSizeMap(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_upscaledDepthPixSizeMap_dmp,
                                           const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_sgmDepthThicknessMap_dmp,
                                           const int rcDeviceCameraParamsId,
                                           const DeviceMipmapImage& rcDeviceMipmapImage,
                                           const RefineParams& refineParams,
                                           const ROI& roi,
                                           id<MTLDevice> dev);

/**
 * @brief Upscale the given normal map
 * @param[out] out_upscaledMap_dmp The output upscaled normal map
 * @param[in] in_map_dmp The normal map to upscaled
 * @param[in] roi The 2D region of interest
 * @param[in] dev The device to operate on
 */
void MTL_normalMapUpscale(const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& out_upscaledMap_dmp,
                          const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& in_map_dmp,
                          const ROI& roi,
                          id<MTLDevice> dev);

/**
 * @brief Copy depth and default from input depth/sim map to another depth/sim map
 * @param[out] out_depthSimMap_dmp The output depth/sim map
 * @param[in] in_depthSimMap_dmp The input depth/sim map to copy
 * @param[in] defaultSim The default similarity value to copy
 * @param[in] dev The device to operate on
 */
void MTL_depthSimMapCopyDepthOnly(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_depthSimMap_dmp,
                                  const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_depthSimMap_dmp,
                                  float defaultSim,
                                  id<MTLDevice> dev);

/**
 * @brief Optimize a depth/sim map with the refineFused depth/sim map and the SGM depth/pixSize map
 * @param[out] out_optimizeDepthSimMap_dmp The output optimized depth/sim map
 * @param[in,out] inout_imgVariance_dmp The image variance buffer
 * @param[in,out] inout_tmpOptDepthMap_dmp The temporary optimized depth map buffer
 * @param[in] in_sgmDepthPixSizeMap_dmp The input SGM upscaled depth/pixSize map
 * @param[in] in_refineDepthSimMap_dmp The input refined and fused depth/sim map
 * @param[in] rcDeviceCameraParamsId The R camera parameters id for array in device constant memory
 * @param[in] rcDeviceMipmapImage The R mipmap image in device memory container
 * @param[in] refineParams The Refine parameters
 * @param[in] roi The 2D region of interest
 * @param[in] dev The device to operate on
 */
void MTL_depthSimMapOptimizeGradientDescent(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_optimizeDepthSimMap_dmp,
                                            const std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>& inout_imgVariance_dmp,
                                            const std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>& inout_tmpOptDepthMap_dmp,
                                            const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_sgmDepthPixSizeMap_dmp,
                                            const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_refineDepthSimMap_dmp,
                                            const int rcDeviceCameraParamsId,
                                            const DeviceMipmapImage& rcDeviceMipmapImage,
                                            const RefineParams& refineParams,
                                            const ROI& roi,
                                            id<MTLDevice> dev);

}  // namespace aliceVision::depthMap::mtl
